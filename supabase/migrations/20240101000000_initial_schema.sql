-- =====================================================
-- GROCERY APP SUPABASE SCHEMA (SIMPLE VERSION)
-- =====================================================

-- Row Level Security (RLS) wird für jede Tabelle individuell aktiviert

-- =====================================================
-- 1. LISTS TABLE
-- =====================================================

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

-- Enable RLS
ALTER TABLE lists ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. LIST_MEMBERS TABLE (many-to-many relationship)
-- =====================================================

CREATE TABLE list_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  list_id UUID REFERENCES lists(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role TEXT CHECK (role IN ('owner', 'editor', 'viewer')) DEFAULT 'viewer',
  invited_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  accepted_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(list_id, user_id)
);

-- Enable RLS
ALTER TABLE list_members ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. CATEGORIES TABLE (read-only for normal users)
-- =====================================================

CREATE TABLE categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT DEFAULT 'basket-shopping',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4. UNITS TABLE (read-only for normal users)
-- =====================================================

CREATE TABLE units (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  short_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE units ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. SHOPPING_ITEMS TABLE
-- =====================================================

CREATE TABLE shopping_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  list_id UUID REFERENCES lists(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  quantity DECIMAL(10,2),
  unit_id UUID REFERENCES units(id),
  category_id UUID REFERENCES categories(id),
  notes TEXT,
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

-- Enable RLS
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

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
-- RLS POLICIES
-- =====================================================

-- =====================================================
-- LISTS POLICIES
-- =====================================================

-- Users can view lists they are members of
CREATE POLICY "Users can view lists they are members of" ON lists
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM list_members 
      WHERE list_id = lists.id 
      AND user_id = auth.uid()
    )
  );

-- Users can create lists
CREATE POLICY "Users can create lists" ON lists
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Users can update lists they own or have editor role
CREATE POLICY "Users can update lists they own or have editor role" ON lists
  FOR UPDATE USING (
    auth.uid() = created_by OR
    EXISTS (
      SELECT 1 FROM list_members 
      WHERE list_id = lists.id 
      AND user_id = auth.uid() 
      AND role IN ('owner', 'editor')
    )
  );

-- =====================================================
-- LIST_MEMBERS POLICIES
-- =====================================================

-- Users can view members of lists they are members of
CREATE POLICY "Users can view list members" ON list_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM list_members lm2
      WHERE lm2.list_id = list_members.list_id 
      AND lm2.user_id = auth.uid()
    )
  );

-- List owners can add members
CREATE POLICY "List owners can add members" ON list_members
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM lists l
      JOIN list_members lm ON l.id = lm.list_id
      WHERE l.id = list_members.list_id
      AND lm.user_id = auth.uid()
      AND lm.role = 'owner'
    )
  );

-- List owners can update member roles
CREATE POLICY "List owners can update member roles" ON list_members
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM lists l
      JOIN list_members lm ON l.id = lm.list_id
      WHERE l.id = list_members.list_id
      AND lm.user_id = auth.uid()
      AND lm.role = 'owner'
    )
  );

-- Users can remove themselves from lists
CREATE POLICY "Users can remove themselves from lists" ON list_members
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- CATEGORIES POLICIES (Read-only for normal users)
-- =====================================================

-- Everyone can read categories
CREATE POLICY "Everyone can read categories" ON categories
  FOR SELECT USING (true);

-- Only admins can modify categories (you'll need to implement admin check)
-- For now, we'll allow authenticated users to modify (you can restrict this later)
CREATE POLICY "Authenticated users can modify categories" ON categories
  FOR ALL USING (auth.uid() IS NOT NULL);

-- =====================================================
-- UNITS POLICIES (Read-only for normal users)
-- =====================================================

-- Everyone can read units
CREATE POLICY "Everyone can read units" ON units
  FOR SELECT USING (true);

-- Only admins can modify units (you'll need to implement admin check)
-- For now, we'll allow authenticated users to modify (you can restrict this later)
CREATE POLICY "Authenticated users can modify units" ON units
  FOR ALL USING (auth.uid() IS NOT NULL);

-- =====================================================
-- SHOPPING_ITEMS POLICIES
-- =====================================================

-- Users can view items in lists they are members of
CREATE POLICY "Users can view shopping items in their lists" ON shopping_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM list_members 
      WHERE list_id = shopping_items.list_id 
      AND user_id = auth.uid()
    )
  );

-- Users can create items in lists they are members of
CREATE POLICY "Users can create shopping items in their lists" ON shopping_items
  FOR INSERT WITH CHECK (
    auth.uid() = created_by AND
    EXISTS (
      SELECT 1 FROM list_members 
      WHERE list_id = shopping_items.list_id 
      AND user_id = auth.uid()
    )
  );

-- Users can update items in lists they are members of
CREATE POLICY "Users can update shopping items in their lists" ON shopping_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM list_members 
      WHERE list_id = shopping_items.list_id 
      AND user_id = auth.uid()
    )
  );

-- Users can delete (soft delete) items in lists they are members of
CREATE POLICY "Users can soft delete shopping items in their lists" ON shopping_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM list_members 
      WHERE list_id = shopping_items.list_id 
      AND user_id = auth.uid()
    )
  );

-- =====================================================
-- FUNCTIONS FOR SOFT DELETE
-- =====================================================

-- Function to soft delete a list
CREATE OR REPLACE FUNCTION soft_delete_list(list_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE lists 
  SET is_deleted = TRUE, 
      deleted_at = NOW(), 
      deleted_by = auth.uid()
  WHERE id = list_uuid 
  AND EXISTS (
    SELECT 1 FROM list_members 
    WHERE list_id = list_uuid 
    AND user_id = auth.uid() 
    AND role IN ('owner', 'editor')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to soft delete a shopping item
CREATE OR REPLACE FUNCTION soft_delete_shopping_item(item_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE shopping_items 
  SET is_deleted = TRUE, 
      deleted_at = NOW(), 
      deleted_by = auth.uid()
  WHERE id = item_uuid 
  AND EXISTS (
    SELECT 1 FROM list_members 
    WHERE list_id = shopping_items.list_id 
    AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_lists_updated_at BEFORE UPDATE ON lists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_units_updated_at BEFORE UPDATE ON units
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shopping_items_updated_at BEFORE UPDATE ON shopping_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- INITIAL DATA
-- =====================================================

-- Insert default categories
INSERT INTO categories (name, icon) VALUES
  ('Obst & Gemüse', 'apple-alt'),
  ('Milchprodukte', 'cheese'),
  ('Fleisch & Fisch', 'drumstick-bite'),
  ('Backwaren', 'bread-slice'),
  ('Getränke', 'wine-bottle'),
  ('Haushalt', 'home'),
  ('Hygiene', 'soap'),
  ('Tiefkühlkost', 'snowflake'),
  ('Konserven', 'can-food'),
  ('Gewürze & Öle', 'mortar-pestle');

-- Insert default units
INSERT INTO units (name, short_name) VALUES
  ('Stück', 'Stk'),
  ('Kilogramm', 'kg'),
  ('Gramm', 'g'),
  ('Liter', 'L'),
  ('Milliliter', 'ml'),
  ('Packung', 'Pkg'),
  ('Dose', 'Dose'),
  ('Flasche', 'Flasche'),
  ('Tüte', 'Tüte'),
  ('Bund', 'Bund');

-- =====================================================
-- VIEWS FOR EASIER QUERYING
-- =====================================================

-- View for lists with member count
CREATE VIEW lists_with_member_count AS
SELECT 
  l.*,
  COUNT(lm.user_id) as member_count
FROM lists l
LEFT JOIN list_members lm ON l.id = lm.list_id
WHERE l.is_deleted = FALSE
GROUP BY l.id;

-- View for shopping items with category and unit info
CREATE VIEW shopping_items_with_details AS
SELECT 
  si.*,
  c.name as category_name,
  c.icon as category_icon,
  u.name as unit_name,
  u.short_name as unit_short_name
FROM shopping_items si
LEFT JOIN categories c ON si.category_id = c.id
LEFT JOIN units u ON si.unit_id = u.id
WHERE si.is_deleted = FALSE;

-- =====================================================
-- GRANTS
-- =====================================================

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated; 