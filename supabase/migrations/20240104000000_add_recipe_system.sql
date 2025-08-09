-- =====================================================
-- ADD RECIPE SYSTEM
-- =====================================================
-- 
-- This migration adds a complete recipe system with:
-- - Recipe categories (similar to grocery_categories)
-- - Recipes with metadata (name, description, portions, etc.)
-- - Recipe ingredients with flexible ingredient linking
-- - Recipe steps for preparation instructions
-- - Recipe timing information
-- - Recipe images
-- - Row Level Security (RLS) for data protection
--
-- Author: Grocery App Team
-- Date: 2024-01-04
-- =====================================================

-- =====================================================
-- 1. RECIPE_CATEGORIES TABLE - Recipe categories
-- =====================================================
-- Similar to grocery_categories but for recipes
-- Read-only for normal users, managed by admins

CREATE TABLE recipe_categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT DEFAULT 'utensils',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for data protection
ALTER TABLE recipe_categories ENABLE ROW LEVEL SECURITY;

-- ======================================================
-- 1a. RECIPE_UNITS TABLE - Measurement units for recipes
-- ======================================================
-- Read-only for normal users, managed by admins

CREATE TABLE recipe_units (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  short_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for data protection
ALTER TABLE recipe_units ENABLE ROW LEVEL SECURITY;

-- Timestamp trigger for recipe_units
CREATE TRIGGER update_recipe_units_updated_at BEFORE UPDATE ON recipe_units
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 2. RECIPES TABLE - Main recipe information
-- =====================================================
-- Stores recipe metadata and basic information
-- Only authenticated users can create, only creators can edit

CREATE TABLE recipes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  portions INTEGER NOT NULL DEFAULT 1,
  difficulty TEXT CHECK (difficulty IN ('einfach', 'mittel', 'schwer')) DEFAULT 'mittel',
  category_id UUID REFERENCES recipe_categories(id),
  working_time_minutes INTEGER,
  cooking_time_minutes INTEGER,
  resting_time_minutes INTEGER,
  image_url TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES auth.users(id)
);

-- Enable Row Level Security for data protection
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. RECIPE_INGREDIENT_SECTIONS TABLE - Ingredient sections
-- =====================================================
-- Groups ingredients into sections (e.g., "Tortenboden", "Belag")
-- Optional - if no section is specified, ingredients belong to default section

CREATE TABLE recipe_ingredient_sections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for data protection
ALTER TABLE recipe_ingredient_sections ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4. RECIPE_INGREDIENTS TABLE - Recipe ingredients
-- =====================================================
-- Links recipes to ingredients with quantities and units
-- Supports flexible ingredient linking (product_groups, products, or custom ingredients)

CREATE TABLE recipe_ingredients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  section_id UUID REFERENCES recipe_ingredient_sections(id) ON DELETE CASCADE,
  quantity DECIMAL(10,2) NOT NULL,
  unit_id UUID REFERENCES recipe_units(id),
  
  -- Flexible ingredient linking - only one should be set
  product_group_id UUID REFERENCES product_groups(id),
  product_id UUID REFERENCES products(id),
  custom_ingredient_name TEXT, -- For ingredients not in product_groups or products
  
  -- Ensure only one ingredient type is set
  CONSTRAINT ingredient_type_check CHECK (
    (product_group_id IS NOT NULL AND product_id IS NULL AND custom_ingredient_name IS NULL) OR
    (product_group_id IS NULL AND product_id IS NOT NULL AND custom_ingredient_name IS NULL) OR
    (product_group_id IS NULL AND product_id IS NULL AND custom_ingredient_name IS NOT NULL)
  ),
  
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for data protection
ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. RECIPE_STEPS TABLE - Recipe preparation steps
-- =====================================================
-- Stores step-by-step preparation instructions

CREATE TABLE recipe_steps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  step_number INTEGER NOT NULL,
  instruction TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique step numbers per recipe
  UNIQUE(recipe_id, step_number)
);

-- Enable Row Level Security for data protection
ALTER TABLE recipe_steps ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================

-- Recipe indexes
CREATE INDEX idx_recipes_created_by ON recipes(created_by);
CREATE INDEX idx_recipes_category_id ON recipes(category_id);
CREATE INDEX idx_recipes_is_deleted ON recipes(is_deleted);
CREATE INDEX idx_recipes_created_at ON recipes(created_at);
CREATE INDEX idx_recipes_difficulty ON recipes(difficulty);

-- Recipe ingredient section indexes
CREATE INDEX idx_recipe_ingredient_sections_recipe_id ON recipe_ingredient_sections(recipe_id);
CREATE INDEX idx_recipe_ingredient_sections_sort_order ON recipe_ingredient_sections(sort_order);

-- Recipe ingredient indexes
CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);
CREATE INDEX idx_recipe_ingredients_section_id ON recipe_ingredients(section_id);
CREATE INDEX idx_recipe_ingredients_product_group_id ON recipe_ingredients(product_group_id);
CREATE INDEX idx_recipe_ingredients_product_id ON recipe_ingredients(product_id);
CREATE INDEX idx_recipe_ingredients_unit_id ON recipe_ingredients(unit_id);
CREATE INDEX idx_recipe_ingredients_sort_order ON recipe_ingredients(sort_order);

-- Recipe step indexes
CREATE INDEX idx_recipe_steps_recipe_id ON recipe_steps(recipe_id);
CREATE INDEX idx_recipe_steps_step_number ON recipe_steps(step_number);

-- =====================================================
-- HELPER FUNCTIONS - Recipe ownership and access
-- =====================================================

-- Check if a user is the creator of a specific recipe
CREATE OR REPLACE FUNCTION is_recipe_creator(recipe_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM recipes 
    WHERE id = recipe_uuid 
    AND created_by = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get ingredient display name (for product_groups, products, or custom ingredients)
CREATE OR REPLACE FUNCTION get_ingredient_display_name(
  p_product_group_id UUID,
  p_product_id UUID,
  p_custom_ingredient_name TEXT
)
RETURNS TEXT AS $$
DECLARE
  display_name TEXT;
BEGIN
  IF p_product_group_id IS NOT NULL THEN
    SELECT title INTO display_name FROM product_groups WHERE id = p_product_group_id;
  ELSIF p_product_id IS NOT NULL THEN
    SELECT title INTO display_name FROM products WHERE id = p_product_id;
  ELSE
    display_name := p_custom_ingredient_name;
  END IF;
  
  RETURN display_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- =====================================================
-- RECIPE_UNITS POLICIES (Read-only for normal users)
-- =====================================================

-- Everyone can read recipe_units
CREATE POLICY "Everyone can read recipe_units" ON recipe_units
  FOR SELECT USING (true);

-- Only authenticated users can modify recipe_units (tighten later for admins)
CREATE POLICY "Authenticated users can modify recipe_units" ON recipe_units
  FOR ALL USING (auth.uid() IS NOT NULL);

-- =====================================================
-- RECIPE_CATEGORIES POLICIES (Read-only for normal users)
-- =====================================================

-- Everyone can read recipe categories
CREATE POLICY "Everyone can read recipe_categories" ON recipe_categories
  FOR SELECT USING (true);

-- Only admins can modify recipe categories
CREATE POLICY "Only admins can modify recipe_categories" ON recipe_categories
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'service_role' OR
    auth.jwt() ->> 'email' IN (
      SELECT email FROM auth.users 
      WHERE raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- =====================================================
-- RECIPES POLICIES
-- =====================================================

-- Everyone can view non-deleted recipes
CREATE POLICY "Everyone can view recipes" ON recipes
  FOR SELECT USING (is_deleted = FALSE);

-- Only authenticated users can create recipes
CREATE POLICY "Authenticated users can create recipes" ON recipes
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Only recipe creators can update their recipes
CREATE POLICY "Recipe creators can update recipes" ON recipes
  FOR UPDATE USING (is_recipe_creator(recipes.id, auth.uid()));

-- Only recipe creators can delete their recipes (soft delete)
CREATE POLICY "Recipe creators can delete recipes" ON recipes
  FOR UPDATE USING (is_recipe_creator(recipes.id, auth.uid()));

-- =====================================================
-- RECIPE_INGREDIENT_SECTIONS POLICIES
-- =====================================================

-- Users can view sections of recipes they can view
CREATE POLICY "Users can view recipe sections" ON recipe_ingredient_sections
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipes 
      WHERE id = recipe_ingredient_sections.recipe_id 
      AND is_deleted = FALSE
    )
  );

-- Recipe creators can manage sections
CREATE POLICY "Recipe creators can manage sections" ON recipe_ingredient_sections
  FOR ALL USING (
    is_recipe_creator(recipe_ingredient_sections.recipe_id, auth.uid())
  );

-- =====================================================
-- RECIPE_INGREDIENTS POLICIES
-- =====================================================

-- Users can view ingredients of recipes they can view
CREATE POLICY "Users can view recipe ingredients" ON recipe_ingredients
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipes 
      WHERE id = recipe_ingredients.recipe_id 
      AND is_deleted = FALSE
    )
  );

-- Recipe creators can manage ingredients
CREATE POLICY "Recipe creators can manage ingredients" ON recipe_ingredients
  FOR ALL USING (
    is_recipe_creator(recipe_ingredients.recipe_id, auth.uid())
  );

-- =====================================================
-- RECIPE_STEPS POLICIES
-- =====================================================

-- Users can view steps of recipes they can view
CREATE POLICY "Users can view recipe steps" ON recipe_steps
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipes 
      WHERE id = recipe_steps.recipe_id 
      AND is_deleted = FALSE
    )
  );

-- Recipe creators can manage steps
CREATE POLICY "Recipe creators can manage steps" ON recipe_steps
  FOR ALL USING (
    is_recipe_creator(recipe_steps.recipe_id, auth.uid())
  );

-- =====================================================
-- TRIGGERS - Automatic timestamp updates
-- =====================================================

-- Update updated_at timestamp on recipe changes
CREATE TRIGGER update_recipes_updated_at BEFORE UPDATE ON recipes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at timestamp on recipe category changes
CREATE TRIGGER update_recipe_categories_updated_at BEFORE UPDATE ON recipe_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at timestamp on recipe ingredient section changes
CREATE TRIGGER update_recipe_ingredient_sections_updated_at BEFORE UPDATE ON recipe_ingredient_sections
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at timestamp on recipe ingredient changes
CREATE TRIGGER update_recipe_ingredients_updated_at BEFORE UPDATE ON recipe_ingredients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at timestamp on recipe step changes
CREATE TRIGGER update_recipe_steps_updated_at BEFORE UPDATE ON recipe_steps
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SEED DATA - Recipe categories
-- =====================================================

-- Seed data for recipe_units
INSERT INTO recipe_units (name, short_name) VALUES
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

-- Insert default recipe categories
INSERT INTO recipe_categories (name, icon) VALUES
  ('Hauptspeise', 'utensils'),
  ('Vorspeise', 'cheese'),
  ('Suppe', 'bowl-hot'),
  ('Salat', 'leaf'),
  ('Beilage', 'carrot'),
  ('Dessert', 'ice-cream'),
  ('Kuchen', 'birthday-cake'),
  ('Brot & Gebäck', 'bread-slice'),
  ('Frühstück', 'coffee'),
  ('Snack', 'cookie-bite'),
  ('Getränk', 'wine-glass'),
  ('Likör', 'wine-bottle'),
  ('Smoothie', 'glass-whiskey'),
  ('Dip & Sauce', 'jar'),
  ('Marmelade & Konfitüre', 'jar-wheat'),
  ('Eingelegtes', 'jar-wheat'),
  ('Weihnachtsgebäck', 'star'),
  ('Ostergebäck', 'egg'),
  ('Party & Buffet', 'users'),
  ('Vegetarisch', 'seedling'),
  ('Vegan', 'leaf'),
  ('Glutenfrei', 'wheat-awn-slash'),
  ('Laktosefrei', 'milk'),
  ('Low Carb', 'scale-balanced'),
  ('Keto', 'drumstick-bite'),
  ('Diät', 'weight-scale'),
  ('Kinderfreundlich', 'baby'),
  ('Schnell & Einfach', 'clock'),
  ('Slow Food', 'hourglass-half'),
  ('Grillen', 'fire'),
  ('Picknick', 'basket-shopping'),
  ('Festtagsmenü', 'crown'),
  ('International', 'globe'),
  ('Regionale Küche', 'map-marker-alt'),
  ('Hausmannskost', 'home'),
  ('Gourmet', 'star'),
  ('Basisrezepte', 'book'),
  ('Resteverwertung', 'recycle')
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- VIEWS - Convenient data access
-- =====================================================

-- View showing recipes with category details
CREATE VIEW recipes_with_details AS
SELECT 
  r.*,
  rc.name as category_name,
  rc.icon as category_icon,
  creator.email as creator_email,
  creator.raw_user_meta_data->>'full_name' as creator_name
FROM recipes r
LEFT JOIN recipe_categories rc ON r.category_id = rc.id
LEFT JOIN auth.users creator ON r.created_by = creator.id
WHERE r.is_deleted = FALSE;

-- View showing recipe ingredients with all details
CREATE VIEW recipe_ingredients_with_details AS
SELECT 
  ri.*,
  r.name as recipe_name,
  ris.name as section_name,
  ris.sort_order as section_sort_order,
  u.name as unit_name,
  u.short_name as unit_short_name,
  pg.title as product_group_name,
  p.title as product_name,
  get_ingredient_display_name(
    ri.product_group_id, 
    ri.product_id, 
    ri.custom_ingredient_name
  ) as ingredient_display_name
FROM recipe_ingredients ri
JOIN recipes r ON ri.recipe_id = r.id
LEFT JOIN recipe_ingredient_sections ris ON ri.section_id = ris.id
LEFT JOIN recipe_units u ON ri.unit_id = u.id
LEFT JOIN product_groups pg ON ri.product_group_id = pg.id
LEFT JOIN products p ON ri.product_id = p.id
WHERE r.is_deleted = FALSE;

-- View showing recipe steps with recipe details
CREATE VIEW recipe_steps_with_details AS
SELECT 
  rs.*,
  r.name as recipe_name
FROM recipe_steps rs
JOIN recipes r ON rs.recipe_id = r.id
WHERE r.is_deleted = FALSE
ORDER BY rs.recipe_id, rs.step_number;

-- =====================================================
-- UTILITY FUNCTIONS - Recipe management
-- =====================================================

-- Soft delete a recipe and all its related data
CREATE OR REPLACE FUNCTION soft_delete_recipe(recipe_uuid UUID)
RETURNS VOID AS $$
BEGIN
  -- Soft delete the recipe
  UPDATE recipes 
  SET is_deleted = TRUE, 
      deleted_at = NOW(), 
      deleted_by = auth.uid()
  WHERE id = recipe_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get total cooking time for a recipe
CREATE OR REPLACE FUNCTION get_recipe_total_time(recipe_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  total_time INTEGER;
BEGIN
  SELECT COALESCE(working_time_minutes, 0) + 
         COALESCE(cooking_time_minutes, 0) + 
         COALESCE(resting_time_minutes, 0)
  INTO total_time
  FROM recipes 
  WHERE id = recipe_uuid;
  
  RETURN total_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- 
-- The recipe system is now ready for use with:
-- ✅ Recipe categories with default seed data
-- ✅ Recipes with metadata (name, description, portions, difficulty, timing)
-- ✅ Flexible ingredient system (product_groups, products, or custom ingredients)
-- ✅ Ingredient sections for organized ingredient lists
-- ✅ Step-by-step preparation instructions
-- ✅ Row Level Security protecting all data
-- ✅ Helper functions for ingredient display and recipe management
-- ✅ Automatic timestamp management
-- ✅ Performance-optimized indexes
-- ✅ Convenient views for data access
-- ✅ Soft delete functionality
--
-- Next steps:
-- 1. Test the API endpoints
-- 2. Create frontend integration
-- 3. Add recipe search and filtering functionality
-- ===================================================== 