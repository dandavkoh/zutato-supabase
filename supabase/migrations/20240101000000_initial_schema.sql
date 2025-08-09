-- =====================================================
-- GROCERY APP SUPABASE SCHEMA - FINAL VERSION
-- =====================================================
-- 
-- This migration creates a complete grocery list sharing system with:
-- - User authentication and authorization
-- - Shared lists with member management
-- - Shopping items with categories and units
-- - Row Level Security (RLS) for data protection
-- - Helper functions to avoid infinite recursion in policies
--
-- Author: Grocery App Team
-- Date: 2024-01-01
-- =====================================================

-- =====================================================
-- 1. LISTS TABLE - Core table for grocery lists
-- =====================================================
-- Stores grocery lists that can be shared between users
-- Each list has an owner (created_by) and can have multiple members

CREATE TABLE lists (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES auth.users(id)
);

-- Enable Row Level Security for data protection
ALTER TABLE lists ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. LIST_MEMBERS TABLE - Many-to-many relationship
-- =====================================================
-- Manages which users have access to which lists
-- Supports different roles: owner, editor, viewer
-- Prevents infinite recursion in RLS policies through helper functions

CREATE TABLE list_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  list_id UUID REFERENCES lists(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role TEXT CHECK (role IN ('owner', 'editor', 'viewer')) DEFAULT 'viewer',
  invited_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  accepted_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(list_id, user_id)  -- Prevent duplicate memberships
);

-- Enable Row Level Security for data protection
ALTER TABLE list_members ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. GROCERY_CATEGORIES TABLE - Predefined item categories
-- =====================================================
-- Read-only for normal users, managed by admins
-- Provides organization for shopping items

CREATE TABLE grocery_categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT DEFAULT 'basket-shopping',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for data protection
ALTER TABLE grocery_categories ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4. GROCERY_UNITS TABLE - Measurement units for items
-- =====================================================
-- Read-only for normal users, managed by admins
-- Provides standardized units for quantities

CREATE TABLE grocery_units (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  short_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for data protection
ALTER TABLE grocery_units ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. SHOPPING_ITEMS TABLE - Individual grocery items
-- =====================================================
-- Stores items within lists with quantities, categories, and completion status
-- Supports soft deletion and completion tracking

CREATE TABLE shopping_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  list_id UUID REFERENCES lists(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  quantity DECIMAL(10,2),
  unit_id UUID REFERENCES grocery_units(id),
  category_id UUID REFERENCES grocery_categories(id),
  icon TEXT,
  notes TEXT,
  store TEXT,
  assigned_to UUID REFERENCES auth.users(id),
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  completed_by UUID REFERENCES auth.users(id),
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES auth.users(id)
);

-- Enable Row Level Security for data protection
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================
-- These indexes improve query performance for common operations

-- Lists indexes
CREATE INDEX idx_lists_created_by ON lists(created_by);
CREATE INDEX idx_lists_is_deleted ON lists(is_deleted);
CREATE INDEX idx_lists_created_at ON lists(created_at);

-- List members indexes
CREATE INDEX idx_list_members_list_id ON list_members(list_id);
CREATE INDEX idx_list_members_user_id ON list_members(user_id);
CREATE INDEX idx_list_members_role ON list_members(role);

-- Shopping items indexes
CREATE INDEX idx_shopping_items_list_id ON shopping_items(list_id);
CREATE INDEX idx_shopping_items_category_id ON shopping_items(category_id);
CREATE INDEX idx_shopping_items_unit_id ON shopping_items(unit_id);
CREATE INDEX idx_shopping_items_created_by ON shopping_items(created_by);
CREATE INDEX idx_shopping_items_is_deleted ON shopping_items(is_deleted);
CREATE INDEX idx_shopping_items_is_completed ON shopping_items(is_completed);

-- =====================================================
-- HELPER FUNCTIONS - Avoid infinite recursion in RLS
-- =====================================================
-- These functions encapsulate membership and ownership checks
-- They prevent circular references that cause infinite recursion in policies
-- SECURITY DEFINER ensures they run with elevated privileges for performance

-- Check if a user is a member of a specific list
CREATE OR REPLACE FUNCTION is_list_member(list_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM list_members 
    WHERE list_id = list_uuid 
    AND user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if a user is the owner of a specific list
CREATE OR REPLACE FUNCTION is_list_owner(list_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM lists 
    WHERE id = list_uuid 
    AND created_by = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if a user has editor or owner role in a list
CREATE OR REPLACE FUNCTION has_editor_role(list_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM list_members 
    WHERE list_id = list_uuid 
    AND user_id = user_uuid
    AND role IN ('owner', 'editor')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================
-- These policies control access to data based on user relationships
-- They ensure users can only access data they're authorized to see

-- =====================================================
-- LISTS POLICIES
-- =====================================================

-- Users can view lists they own or are members of
CREATE POLICY "Users can view shared lists" ON lists
  FOR SELECT USING (
    is_list_owner(lists.id, auth.uid()) OR is_list_member(lists.id, auth.uid())
  );

-- Users can create their own lists
CREATE POLICY "Users can create lists" ON lists
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Users can update lists they own or have editor role
CREATE POLICY "Users can update shared lists" ON lists
  FOR UPDATE USING (
    is_list_owner(lists.id, auth.uid()) OR has_editor_role(lists.id, auth.uid())
  );

-- =====================================================
-- LIST_MEMBERS POLICIES
-- =====================================================

-- Users can view members of lists they're part of
CREATE POLICY "Users can view list members" ON list_members
  FOR SELECT USING (
    auth.uid() = user_id OR 
    is_list_owner(list_members.list_id, auth.uid()) OR
    is_list_member(list_members.list_id, auth.uid())
  );

-- List owners can add new members
CREATE POLICY "List owners can add members" ON list_members
  FOR INSERT WITH CHECK (
    is_list_owner(list_members.list_id, auth.uid())
  );

-- List owners can update member roles
CREATE POLICY "List owners can update member roles" ON list_members
  FOR UPDATE USING (
    is_list_owner(list_members.list_id, auth.uid())
  );

-- Users can remove themselves from lists
CREATE POLICY "Users can remove themselves from lists" ON list_members
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- GROCERY_CATEGORIES POLICIES (Read-only for normal users)
-- =====================================================

-- Everyone can read grocery_categories
CREATE POLICY "Everyone can read grocery_categories" ON grocery_categories
  FOR SELECT USING (true);

-- No write policies for grocery_categories to enforce read-only access

-- =====================================================
-- GROCERY_UNITS POLICIES (Read-only for normal users)
-- =====================================================

-- Everyone can read grocery_units
CREATE POLICY "Everyone can read grocery_units" ON grocery_units
  FOR SELECT USING (true);

-- No write policies for grocery_units to enforce read-only access

-- =====================================================
-- SHOPPING_ITEMS POLICIES
-- =====================================================

-- Users can view items in lists they own or are members of
CREATE POLICY "Users can view shared items" ON shopping_items
  FOR SELECT USING (
    is_list_owner(shopping_items.list_id, auth.uid()) OR 
    is_list_member(shopping_items.list_id, auth.uid())
  );

-- Users can create items in lists they own or have editor role
CREATE POLICY "Users can create shared items" ON shopping_items
  FOR INSERT WITH CHECK (
    auth.uid() = created_by AND
    (is_list_owner(shopping_items.list_id, auth.uid()) OR 
     has_editor_role(shopping_items.list_id, auth.uid()))
  );

-- Users can update items in lists they own or have editor role
CREATE POLICY "Users can update shared items" ON shopping_items
  FOR UPDATE USING (
    is_list_owner(shopping_items.list_id, auth.uid()) OR 
    has_editor_role(shopping_items.list_id, auth.uid())
  );

-- Users can delete items in lists they own or have editor role
CREATE POLICY "Users can delete shared items" ON shopping_items
  FOR DELETE USING (
    is_list_owner(shopping_items.list_id, auth.uid()) OR 
    has_editor_role(shopping_items.list_id, auth.uid())
  );

-- =====================================================
-- UTILITY FUNCTIONS - Soft delete and timestamp management
-- =====================================================

-- Soft delete a list and all its items
CREATE OR REPLACE FUNCTION soft_delete_list(list_uuid UUID)
RETURNS VOID AS $$
BEGIN
  -- Soft delete all items in the list
  UPDATE shopping_items 
  SET is_deleted = TRUE, 
      deleted_at = NOW(), 
      deleted_by = auth.uid()
  WHERE list_id = list_uuid;
  
  -- Soft delete the list
  UPDATE lists 
  SET is_deleted = TRUE, 
      deleted_at = NOW(), 
      deleted_by = auth.uid()
  WHERE id = list_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Soft delete a shopping item
CREATE OR REPLACE FUNCTION soft_delete_shopping_item(item_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE shopping_items 
  SET is_deleted = TRUE, 
      deleted_at = NOW(), 
      deleted_by = auth.uid()
  WHERE id = item_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS - Automatic timestamp updates
-- =====================================================

-- Update updated_at timestamp on list changes
CREATE TRIGGER update_lists_updated_at BEFORE UPDATE ON lists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at timestamp on category changes
CREATE TRIGGER update_grocery_categories_updated_at BEFORE UPDATE ON grocery_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at timestamp on unit changes
CREATE TRIGGER update_grocery_units_updated_at BEFORE UPDATE ON grocery_units
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at timestamp on shopping item changes
CREATE TRIGGER update_shopping_items_updated_at BEFORE UPDATE ON shopping_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SEED DATA - Initial grocery_categories and grocerry_units
-- =====================================================
-- Provides default grocery_categories and grocery_units for new installations

-- Insert default grocery_categories
INSERT INTO grocery_categories (name, icon) VALUES
  ('Obst', 'apple-alt'),
  ('Gemüse', 'carrot'),
  ('Brot & Backwaren', 'bread-slice'),
  ('Milchprodukte & Eier', 'cheese-swiss'),
  ('Fleisch', 'drumstick-bite'),
  ('Fisch & Meeresfrüchte', 'fish'),
  ('Tiefkühlkost', 'snowflake'),
  ('Öl, Essig & Saucen', 'bottle-droplet'),
  ('Brotaufstriche & Dips', 'jar'),
  ('Kräuter & Gewürze', 'leaf'),
  ('Backzutaten', 'pie'),
  ('Nudeln & Reis', 'bowl-chopsticks-noodles'),
  ('Trockenfrüchte & Nüsse', 'chestnut'),
  ('Fertigprodukte', 'boxes-packing'),
  ('Milchersatz', 'box'),
  ('Konserven', 'can-food'),
  ('Cerealien & Müsli', 'bowl-spoon'),
  ('Süßigkeiten & Snacks', 'candy'),
  ('Getränke', 'wine-bottle'),
  ('Haushalt', 'home'),
  ('Drogerie & Kosmetik', 'soap'),
  ('Tier', 'paw'),
  ('Baby & Kind', 'baby'),
  ('Arzneiprodukte', 'prescription-bottle-pill'),
  ('Garten & Baumarkt', 'bag-seedling')
ON CONFLICT (name) DO NOTHING;

-- Insert default grocery_units
INSERT INTO grocery_units (name, short_name) VALUES
  ('Milliliter', 'ml'),
  ('Liter', 'l'),
  ('Gramm', 'g'),
  ('Kilogramm', 'kg'),
  ('Packungen', 'Pkg'),
  ('Flaschen', 'Fl'),
  ('Stück', 'Stk'),
  ('Kästen', 'Kästen'),
  ('Boxen', 'Boxen'),
  ('Gläser', 'Gl'),
  ('Dosen', 'Dosen'),
  ('Bund', 'Bund'),
  ('Tuben', 'Tuben')
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- VIEWS - Convenient data access
-- =====================================================
-- These views provide convenient access to related data

-- View showing lists with member count
CREATE VIEW lists_with_member_count AS
SELECT l.*, COUNT(lm.id) as member_count
FROM lists l
LEFT JOIN list_members lm ON l.id = lm.list_id
WHERE l.is_deleted = FALSE
GROUP BY l.id;

-- View showing shopping items with category and unit details
CREATE VIEW shopping_items_with_details AS
SELECT 
  si.*,
  c.name as category_name,
  c.icon as category_icon,
  u.name as unit_name,
  u.short_name as unit_short_name,
  assigned_user.email as assigned_user_email,
  assigned_user.raw_user_meta_data->>'full_name' as assigned_user_name
FROM shopping_items si
LEFT JOIN grocery_categories c ON si.category_id = c.id
LEFT JOIN grocery_units u ON si.unit_id = u.id
LEFT JOIN auth.users assigned_user ON si.assigned_to = assigned_user.id
WHERE si.is_deleted = FALSE;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- 
-- The schema is now ready for use with:
-- ✅ User authentication and authorization
-- ✅ Shared list functionality with member management
-- ✅ Shopping items with categories and units
-- ✅ Row Level Security protecting all data
-- ✅ Helper functions preventing infinite recursion
-- ✅ Soft delete functionality
-- ✅ Automatic timestamp management
-- ✅ Performance-optimized indexes
-- ✅ Default seed data
-- ✅ Convenient views for data access
--
-- Next steps:
-- 1. Test the API endpoints
-- 2. Create frontend integration
-- 3. Add any additional features as needed
-- ===================================================== 