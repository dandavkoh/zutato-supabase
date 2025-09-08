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
-- 1. RECIPE CATEGORY GROUPS + CATEGORIES
-- =====================================================
-- Read-only for normal users (seeded by migration), used to group categories

CREATE TABLE recipe_category_groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT DEFAULT 'folder',
  sort_order INTEGER NOT NULL DEFAULT 0,
  parent_group_id UUID REFERENCES recipe_category_groups(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE recipe_category_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can read recipe_category_groups" ON recipe_category_groups
  FOR SELECT USING (true);

-- Categories belong to exactly one group; optional parent within same table
CREATE TABLE recipe_categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES recipe_category_groups(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  parent_category_id UUID REFERENCES recipe_categories(id) ON DELETE SET NULL,
  icon TEXT DEFAULT 'utensils',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (group_id, name)
);

ALTER TABLE recipe_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can read recipe_categories" ON recipe_categories
  FOR SELECT USING (true);

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

-- ======================================================
-- 1b. RECIPE_UNITS_TO_GROCERY_UNITS_MAP TABLE - Mapping between recipe and grocery units
-- ======================================================
-- Maps recipe units to grocery units for conversion when creating shopping lists from recipes
-- Read-only for normal users, managed by admins

CREATE TABLE recipe_units_to_grocery_units_map (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  recipe_unit_id UUID NOT NULL REFERENCES recipe_units(id) ON DELETE CASCADE,
  grocery_unit_id UUID NOT NULL REFERENCES grocery_units(id) ON DELETE CASCADE,
  conversion_factor DECIMAL(10,4) NOT NULL DEFAULT 1.0,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique mapping per recipe unit
  UNIQUE(recipe_unit_id, grocery_unit_id)
);

-- Enable Row Level Security for data protection
ALTER TABLE recipe_units_to_grocery_units_map ENABLE ROW LEVEL SECURITY;

-- Timestamp trigger for recipe_units_to_grocery_units_map
CREATE TRIGGER update_recipe_units_to_grocery_units_map_updated_at BEFORE UPDATE ON recipe_units_to_grocery_units_map
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
  -- Draft support and optional descriptions
  is_draft BOOLEAN NOT NULL DEFAULT FALSE,
  user_description TEXT,
  admin_description TEXT,
  portions INTEGER NOT NULL DEFAULT 1,
  difficulty TEXT CHECK (difficulty IN ('einfach', 'mittel', 'schwer')) DEFAULT 'mittel',
  working_time_minutes INTEGER,
  cooking_time_minutes INTEGER,
  resting_time_minutes INTEGER,
  image_url TEXT,
  -- Full-text search vector on recipe name
  fts tsvector GENERATED ALWAYS AS (to_tsvector('german', name)) STORED,
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
-- 2a. RECIPE_CATEGORIES_MAP TABLE - Many-to-many between recipes and categories
-- =====================================================
-- A recipe can have zero or more recipe_categories

CREATE TABLE recipe_categories_map (
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES recipe_categories(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  PRIMARY KEY (recipe_id, category_id)
);

ALTER TABLE recipe_categories_map ENABLE ROW LEVEL SECURITY;

-- RLS: read if recipe visible; write only by recipe creator
CREATE POLICY "Everyone can read recipe_categories_map" ON recipe_categories_map
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipes r
      WHERE r.id = recipe_categories_map.recipe_id
        AND r.is_deleted = FALSE
    )
  );

CREATE POLICY "Recipe creators can insert recipe_categories_map" ON recipe_categories_map
  FOR INSERT WITH CHECK (
    created_by = auth.uid() AND EXISTS (
      SELECT 1 FROM recipes r
      WHERE r.id = recipe_categories_map.recipe_id AND r.created_by = auth.uid()
    )
  );

CREATE POLICY "Recipe creators can delete recipe_categories_map" ON recipe_categories_map
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM recipes r
      WHERE r.id = recipe_categories_map.recipe_id AND r.created_by = auth.uid()
    )
  );

-- Indexes for mapping
CREATE INDEX idx_recipe_categories_map_recipe_id ON recipe_categories_map(recipe_id);
CREATE INDEX idx_recipe_categories_map_category_id ON recipe_categories_map(category_id);

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
CREATE INDEX idx_recipes_is_deleted ON recipes(is_deleted);
CREATE INDEX idx_recipes_created_at ON recipes(created_at);
CREATE INDEX idx_recipes_difficulty ON recipes(difficulty);
-- Full-text search index
CREATE INDEX idx_recipes_fts ON recipes USING gin(fts);
-- Trigram index for fuzzy search on name
CREATE INDEX idx_recipes_name_trgm ON recipes USING gin(name gin_trgm_ops);

-- Recipe ingredient section indexes
CREATE INDEX idx_recipe_ingredient_sections_recipe_id ON recipe_ingredient_sections(recipe_id);
CREATE INDEX idx_recipe_ingredient_sections_sort_order ON recipe_ingredient_sections(sort_order);

-- Recipe units to grocery units mapping indexes
CREATE INDEX idx_recipe_units_to_grocery_units_map_recipe_unit_id ON recipe_units_to_grocery_units_map(recipe_unit_id);
CREATE INDEX idx_recipe_units_to_grocery_units_map_grocery_unit_id ON recipe_units_to_grocery_units_map(grocery_unit_id);

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

-- Hybrid search for recipes by name with normalized ranking
CREATE OR REPLACE FUNCTION search_recipes(
  term text,
  limit_fts int default 10,
  limit_fuzzy int default 10
)
RETURNS TABLE(
  id uuid,
  name text,
  rank double precision,
  src text
) 
LANGUAGE plpgsql 
STABLE 
AS $$
BEGIN
  RETURN QUERY
  (
    -- 1. Fast full-text search matches (normalized with trigram)
    SELECT 
      r.id,
      r.name,
      GREATEST(similarity(r.name, term), ts_rank(r.fts, q.ts))::double precision as rank,
      'fts'::text as src
    FROM recipes r,
         (SELECT websearch_to_tsquery('german', term || ':*') ts) q
    WHERE r.is_deleted = FALSE
      AND r.fts @@ q.ts
    ORDER BY rank DESC
    LIMIT limit_fts
  )
  UNION ALL
  (
    -- 2. Trigram fallback (exclude FTS duplicates)
    SELECT 
      r.id,
      r.name,
      similarity(r.name, term)::double precision as rank,
      'fuzzy'::text as src
    FROM recipes r
    WHERE r.is_deleted = FALSE
      AND r.name % term
      AND NOT r.fts @@ websearch_to_tsquery('german', term || ':*')
    ORDER BY rank DESC
    LIMIT limit_fuzzy
  );
END;
$$;

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

-- Convert recipe unit to grocery unit with conversion factor
CREATE OR REPLACE FUNCTION convert_recipe_unit_to_grocery_unit(
  p_recipe_unit_id UUID,
  p_quantity DECIMAL(10,2)
)
RETURNS TABLE(
  grocery_unit_id UUID,
  grocery_unit_name TEXT,
  grocery_unit_short_name TEXT,
  converted_quantity DECIMAL(10,2),
  conversion_factor DECIMAL(10,4),
  notes TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    gu.id,
    gu.name,
    gu.short_name,
    (p_quantity * rugum.conversion_factor)::DECIMAL(10,2),
    rugum.conversion_factor,
    rugum.notes
  FROM recipe_units_to_grocery_units_map rugum
  JOIN grocery_units gu ON rugum.grocery_unit_id = gu.id
  WHERE rugum.recipe_unit_id = p_recipe_unit_id;
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

-- No write policies for recipe_units to enforce read-only access

-- =====================================================
-- RECIPE_UNITS_TO_GROCERY_UNITS_MAP POLICIES (Read-only for normal users)
-- =====================================================

-- Everyone can read recipe_units_to_grocery_units_map
CREATE POLICY "Everyone can read recipe_units_to_grocery_units_map" ON recipe_units_to_grocery_units_map
  FOR SELECT USING (true);

-- No write policies for recipe_units_to_grocery_units_map to enforce read-only access

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

-- Authenticated users can create sections
CREATE POLICY "Authenticated recipe creators can create sections" ON recipe_ingredient_sections
  FOR INSERT WITH CHECK (
    is_recipe_creator(recipe_ingredient_sections.recipe_id, auth.uid())
  );

-- Only recipe creators can update sections
CREATE POLICY "Recipe creators can update sections" ON recipe_ingredient_sections
  FOR UPDATE USING (
    is_recipe_creator(recipe_ingredient_sections.recipe_id, auth.uid())
  ) WITH CHECK (
    is_recipe_creator(recipe_ingredient_sections.recipe_id, auth.uid())
  );

-- Only recipe creators can delete sections
CREATE POLICY "Recipe creators can delete sections" ON recipe_ingredient_sections
  FOR DELETE USING (
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

-- Authenticated users can create ingredients
CREATE POLICY "Authenticated recipe creators can create ingredients" ON recipe_ingredients
  FOR INSERT WITH CHECK (
    is_recipe_creator(recipe_ingredients.recipe_id, auth.uid())
  );

-- Only recipe creators can update ingredients
CREATE POLICY "Recipe creators can update ingredients" ON recipe_ingredients
  FOR UPDATE USING (
    is_recipe_creator(recipe_ingredients.recipe_id, auth.uid())
  ) WITH CHECK (
    is_recipe_creator(recipe_ingredients.recipe_id, auth.uid())
  );

-- Only recipe creators can delete ingredients
CREATE POLICY "Recipe creators can delete ingredients" ON recipe_ingredients
  FOR DELETE USING (
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

-- Authenticated users can create steps
CREATE POLICY "Authenticated recipe creators can create steps" ON recipe_steps
  FOR INSERT WITH CHECK (
    is_recipe_creator(recipe_steps.recipe_id, auth.uid())
  );

-- Only recipe creators can update steps
CREATE POLICY "Recipe creators can update steps" ON recipe_steps
  FOR UPDATE USING (
    is_recipe_creator(recipe_steps.recipe_id, auth.uid())
  ) WITH CHECK (
    is_recipe_creator(recipe_steps.recipe_id, auth.uid())
  );

-- Only recipe creators can delete steps
CREATE POLICY "Recipe creators can delete steps" ON recipe_steps
  FOR DELETE USING (
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
  ('Becher', ''),
  ('Beet(e)', ''),
  ('Beutel', ''),
  ('Blatt', ''),
  ('Blätter', ''),
  ('Bund', ''),
  ('Bündel', ''),
  ('cl', ''),
  ('cm', ''),
  ('dicke', ''),
  ('dl', ''),
  ('Dose(n)', ''),
  ('dünne', ''),
  ('Ecke(n)', ''),
  ('Eimer', ''),
  ('einige', ''),
  ('EL', ''),
  ('EL, gehäuft', ''),
  ('EL, gestr.', ''),
  ('etwas', ''),
  ('evtl.', ''),
  ('extra', ''),
  ('Fässchen', ''),
  ('Fläschchen', ''),
  ('Flasche(n)', ''),
  ('g', ''),
  ('Glas', ''),
  ('Gläser', ''),
  ('große', ''),
  ('großen', ''),
  ('großer', ''),
  ('großes', ''),
  ('halbe', ''),
  ('Halm(e)', ''),
  ('Handvoll', ''),
  ('Kästchen', ''),
  ('kg', ''),
  ('kleine', ''),
  ('kleiner', ''),
  ('kleines', ''),
  ('Knolle(n)', ''),
  ('Kopf', ''),
  ('Köpfe', ''),
  ('Körner', ''),
  ('Kugel(n)', ''),
  ('Liter', ''),
  ('mehr', ''),
  ('mg', ''),
  ('ml', ''),
  ('Msp.', ''),
  ('n. B.', ''),
  ('Paar', ''),
  ('Paket(e)', ''),
  ('Pck.', ''),
  ('Pkt.', ''),
  ('Platte(n)', ''),
  ('Port.', ''),
  ('Prise(n)', ''),
  ('Prozent %', ''),
  ('Riegel', ''),
  ('Ring(e)', ''),
  ('Rippe(n)', ''),
  ('Rispe(n)', ''),
  ('Rolle(n)', ''),
  ('Schälchen', ''),
  ('Scheibe(n)', ''),
  ('Schuss', ''),
  ('Spritzer', ''),
  ('Stange(n)', ''),
  ('Stängel', ''),
  ('Staude(n)', ''),
  ('Stick(s)', ''),
  ('Stiel(e)', ''),
  ('Streifen', ''),
  ('Stück(e)', ''),
  ('Tablette(n)', ''),
  ('Tafel(n)', ''),
  ('Tasse(n)', ''),
  ('Teil(e)', ''),
  ('TL', ''),
  ('TL, gehäuft', ''),
  ('TL, gestr.', ''),
  ('Topf', ''),
  ('Tropfen', ''),
  ('Tube(n)', ''),
  ('Tüte(n)', ''),
  ('viel', ''),
  ('wenig', ''),
  ('Würfel', ''),
  ('Wurzel(n)', ''),
  ('Zehe(n)', ''),
  ('Zweig(e)', '')
ON CONFLICT (name) DO NOTHING;

-- Seed data for recipe_units_to_grocery_units_map
-- Maps common recipe units to grocery units with conversion factors
INSERT INTO recipe_units_to_grocery_units_map (recipe_unit_id, grocery_unit_id, conversion_factor, notes) VALUES
  -- Weight conversions
  ((SELECT id FROM recipe_units WHERE name = 'g'), (SELECT id FROM grocery_units WHERE name = 'Gramm'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'kg'), (SELECT id FROM grocery_units WHERE name = 'Kilogramm'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'mg'), (SELECT id FROM grocery_units WHERE name = 'Gramm'), 0.001, 'Milligram to gram conversion'),
  
  -- Volume conversions
  ((SELECT id FROM recipe_units WHERE name = 'ml'), (SELECT id FROM grocery_units WHERE name = 'Milliliter'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Liter'), (SELECT id FROM grocery_units WHERE name = 'Liter'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'cl'), (SELECT id FROM grocery_units WHERE name = 'Milliliter'), 10.0, 'Centiliter to milliliter conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'dl'), (SELECT id FROM grocery_units WHERE name = 'Milliliter'), 100.0, 'Deciliter to milliliter conversion'),
  
  -- Spoon measurements (approximate) - map to Milliliter
  ((SELECT id FROM recipe_units WHERE name = 'EL'), (SELECT id FROM grocery_units WHERE name = 'Milliliter'), 15.0, 'Tablespoon to milliliter (approximate)'),
  ((SELECT id FROM recipe_units WHERE name = 'EL, gehäuft'), (SELECT id FROM grocery_units WHERE name = 'Milliliter'), 20.0, 'Heaped tablespoon to milliliter (approximate)'),
  ((SELECT id FROM recipe_units WHERE name = 'EL, gestr.'), (SELECT id FROM grocery_units WHERE name = 'Milliliter'), 12.0, 'Leveled tablespoon to milliliter (approximate)'),
  ((SELECT id FROM recipe_units WHERE name = 'TL'), (SELECT id FROM grocery_units WHERE name = 'Milliliter'), 5.0, 'Teaspoon to milliliter (approximate)'),
  ((SELECT id FROM recipe_units WHERE name = 'TL, gehäuft'), (SELECT id FROM grocery_units WHERE name = 'Milliliter'), 7.0, 'Heaped teaspoon to milliliter (approximate)'),
  ((SELECT id FROM recipe_units WHERE name = 'TL, gestr.'), (SELECT id FROM grocery_units WHERE name = 'Milliliter'), 4.0, 'Leveled teaspoon to milliliter (approximate)'),
  
  -- Cup measurements (approximate) - map to Milliliter
  ((SELECT id FROM recipe_units WHERE name = 'Becher'), (SELECT id FROM grocery_units WHERE name = 'Milliliter'), 250.0, 'Cup to milliliter (approximate)'),
  ((SELECT id FROM recipe_units WHERE name = 'Tasse(n)'), (SELECT id FROM grocery_units WHERE name = 'Milliliter'), 150.0, 'Tea cup to milliliter (approximate)'),
  
  -- Piece-based conversions - map to Stück
  ((SELECT id FROM recipe_units WHERE name = 'Stück(e)'), (SELECT id FROM grocery_units WHERE name = 'Stück'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Kopf'), (SELECT id FROM grocery_units WHERE name = 'Stück'), 1.0, 'Head to piece conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Köpfe'), (SELECT id FROM grocery_units WHERE name = 'Stück'), 1.0, 'Heads to pieces conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Knolle(n)'), (SELECT id FROM grocery_units WHERE name = 'Stück'), 1.0, 'Tuber to piece conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Zehe(n)'), (SELECT id FROM grocery_units WHERE name = 'Stück'), 1.0, 'Clove to piece conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Scheibe(n)'), (SELECT id FROM grocery_units WHERE name = 'Stück'), 1.0, 'Slice to piece conversion'),
  
  -- Bundle-based conversions - map to Bund
  ((SELECT id FROM recipe_units WHERE name = 'Bund'), (SELECT id FROM grocery_units WHERE name = 'Bund'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Bündel'), (SELECT id FROM grocery_units WHERE name = 'Bund'), 1.0, 'Bundle to bundle conversion'),
  
  -- Container-based conversions - map to available grocery units
  ((SELECT id FROM recipe_units WHERE name = 'Dose(n)'), (SELECT id FROM grocery_units WHERE name = 'Dosen'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Glas'), (SELECT id FROM grocery_units WHERE name = 'Gläser'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Gläser'), (SELECT id FROM grocery_units WHERE name = 'Gläser'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Flasche(n)'), (SELECT id FROM grocery_units WHERE name = 'Flaschen'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Tube(n)'), (SELECT id FROM grocery_units WHERE name = 'Tuben'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Tüte(n)'), (SELECT id FROM grocery_units WHERE name = 'Packungen'), 1.0, 'Bag to package conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Paket(e)'), (SELECT id FROM grocery_units WHERE name = 'Packungen'), 1.0, 'Direct conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Pck.'), (SELECT id FROM grocery_units WHERE name = 'Packungen'), 1.0, 'Package abbreviation to package conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Pkt.'), (SELECT id FROM grocery_units WHERE name = 'Packungen'), 1.0, 'Package abbreviation to package conversion'),
  
  -- Special conversions - map to Stück
  ((SELECT id FROM recipe_units WHERE name = 'Port.'), (SELECT id FROM grocery_units WHERE name = 'Stück'), 1.0, 'Portion to piece conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Teil(e)'), (SELECT id FROM grocery_units WHERE name = 'Stück'), 1.0, 'Part to piece conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Riegel'), (SELECT id FROM grocery_units WHERE name = 'Stück'), 1.0, 'Bar to piece conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Tafel(n)'), (SELECT id FROM grocery_units WHERE name = 'Stück'), 1.0, 'Bar to piece conversion'),
  ((SELECT id FROM recipe_units WHERE name = 'Tablette(n)'), (SELECT id FROM grocery_units WHERE name = 'Stück'), 1.0, 'Tablet to piece conversion')
ON CONFLICT (recipe_unit_id, grocery_unit_id) DO NOTHING;

-- Insert default recipe category groups
INSERT INTO recipe_category_groups (name, icon, sort_order) VALUES
  ('Backen & Süßspeisen', 'cake', 1),
  ('Regional', 'globe', 2),
  ('Zubereitungsarten', 'utensils', 3),
  ('Getränke', 'wine-glass', 4),
  ('Saisonal', 'calendar', 5),
  ('Menüart', 'plate-wheat', 6),
  ('Spezielles', 'star', 7)
ON CONFLICT (name) DO NOTHING;

-- Backen & Süßspeisen
WITH g AS (SELECT id FROM recipe_category_groups WHERE name = 'Backen & Süßspeisen')
INSERT INTO recipe_categories (group_id, name, icon)
SELECT g.id, x.name, 'utensils' FROM g
JOIN (VALUES
  ('Brot und Brötchen'),
  ('Cremes'),
  ('Eis'),
  ('Kekse & Plätzchen'),
  ('Konfiserie'),
  ('Kuchen'),
  ('Tarte/Quiche'),
  ('Torten')
) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Getränke
WITH g AS (SELECT id FROM recipe_category_groups WHERE name = 'Getränke')
INSERT INTO recipe_categories (group_id, name, icon)
SELECT g.id, x.name, 'wine-glass' FROM g
JOIN (VALUES
  ('Bowle'),
  ('Cocktail'),
  ('Kaffee, Tee & Kakao'),
  ('Likör'),
  ('Punsch'),
  ('Shake')
) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Getränke -> Unterkategorien von Cocktail
WITH base AS (
  SELECT c.id, c.group_id FROM recipe_categories c
  JOIN recipe_category_groups g ON g.id = c.group_id
  WHERE g.name = 'Getränke' AND c.name = 'Cocktail'
)
INSERT INTO recipe_categories (group_id, name, parent_category_id, icon)
SELECT base.group_id, x.name, base.id, 'wine-glass' FROM base
JOIN (VALUES('Alkoholfrei'),('Longdrink')) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Saisonal
WITH g AS (SELECT id FROM recipe_category_groups WHERE name = 'Saisonal')
INSERT INTO recipe_categories (group_id, name, icon)
SELECT g.id, x.name, 'calendar' FROM g
JOIN (VALUES
  ('Frühling'),('Halloween'),('Herbst'),('Ostern'),('Silvester'),('Sommer'),('Weihnachten'),('Winter')
) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Zubereitungsarten (Hauptliste)
WITH g AS (SELECT id FROM recipe_category_groups WHERE name = 'Zubereitungsarten')
INSERT INTO recipe_categories (group_id, name, icon)
SELECT g.id, x.name, 'utensils' FROM g
JOIN (VALUES
  ('Aufstrich'),('Backen'),('Beilage'),('Brotspeise'),('Eierspeise'),('Eintopf'),('Fisch'),('Frucht'),('Frühstück'),('Gemüse'),
  ('Gewürze/Öl/Essig/Pasten'),('Grundrezepte'),('Haltbarmachen'),('Krustentier & Muscheln'),('Käse'),('Mehlspeisen'),('Methoden'),
  ('Pasta'),('Saucen'),('Snacks und kleine Gerichte'),('Süßspeisen')
) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Zubereitungsarten -> Methoden Unterkategorien
WITH base AS (
  SELECT c.id, c.group_id FROM recipe_categories c
  JOIN recipe_category_groups g ON g.id = c.group_id
  WHERE g.name = 'Zubereitungsarten' AND c.name = 'Methoden'
)
INSERT INTO recipe_categories (group_id, name, parent_category_id, icon)
SELECT base.group_id, x.name, base.id, 'utensils' FROM base
JOIN (VALUES
  ('Auflauf'),('Barbecue & Grill'),('Blanchieren'),('Braten'),('Dünsten'),('Flambieren'),('Fondue'),('Frittieren'),('Kochen'),
  ('Marinieren'),('Mikrowelle'),('Molekularküche'),('Römertopf'),('Schmoren'),('Wok'),('Überbacken')
) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Menüart (Hauptkategorien)
WITH g AS (SELECT id FROM recipe_category_groups WHERE name = 'Menüart')
INSERT INTO recipe_categories (group_id, name, icon)
SELECT g.id, x.name, 'plate-wheat' FROM g
JOIN (VALUES('Beilage'),('Dessert'),('Frühstück'),('Hauptspeise'),('Salat'),('Suppen'),('Vorspeisen')) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Menüart -> Beilage Unterkategorien
WITH base AS (
  SELECT c.id, c.group_id FROM recipe_categories c
  JOIN recipe_category_groups g ON g.id = c.group_id
  WHERE g.name = 'Menüart' AND c.name = 'Beilage'
)
INSERT INTO recipe_categories (group_id, name, parent_category_id, icon)
SELECT base.group_id, x.name, base.id, 'plate-wheat' FROM base
JOIN (VALUES('Gemüse'),('Hülsenfrüchte'),('Kartoffeln'),('Klöße'),('Nudeln'),('Reis/Getreide')) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Menüart -> Hauptspeise Unterkategorien
WITH base AS (
  SELECT c.id, c.group_id FROM recipe_categories c
  JOIN recipe_category_groups g ON g.id = c.group_id
  WHERE g.name = 'Menüart' AND c.name = 'Hauptspeise'
)
INSERT INTO recipe_categories (group_id, name, parent_category_id, icon)
SELECT base.group_id, x.name, base.id, 'plate-wheat' FROM base
JOIN (VALUES
  ('Eier'),('Eintopf'),('Fisch'),('Geflügel'),('Gemüse'),('Hülsenfrüchte'),('Innereien'),('Kartoffeln'),
  ('Krustentier & Muscheln'),('Lamm & Ziege'),('Pasta & Nudel'),('Pilze'),('Pizza'),('Reis/Getreide'),
  ('Rind'),('Schwein'),('Wild & Kaninchen')
) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Menüart -> Salat Unterkategorien
WITH base AS (
  SELECT c.id, c.group_id FROM recipe_categories c
  JOIN recipe_category_groups g ON g.id = c.group_id
  WHERE g.name = 'Menüart' AND c.name = 'Salat'
)
INSERT INTO recipe_categories (group_id, name, parent_category_id, icon)
SELECT base.group_id, x.name, base.id, 'plate-wheat' FROM base
JOIN (VALUES
  ('Eier & Käse'),('Fleisch & Wurst'),('Früchte'),('Gemüse'),('Kartoffel'),('Krustentier & Fisch'),('Pilze'),
  ('Reis/Nudeln/Getreide'),('Salatdressing'),('Warme Salate')
) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Menüart -> Suppen Unterkategorien
WITH base AS (
  SELECT c.id, c.group_id FROM recipe_categories c
  JOIN recipe_category_groups g ON g.id = c.group_id
  WHERE g.name = 'Menüart' AND c.name = 'Suppen'
)
INSERT INTO recipe_categories (group_id, name, parent_category_id, icon)
SELECT base.group_id, x.name, base.id, 'plate-wheat' FROM base
JOIN (VALUES('Einlagen'),('Gebundene'),('Klare'),('Spezial')) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Menüart -> Vorspeisen Unterkategorien
WITH base AS (
  SELECT c.id, c.group_id FROM recipe_categories c
  JOIN recipe_category_groups g ON g.id = c.group_id
  WHERE g.name = 'Menüart' AND c.name = 'Vorspeisen'
)
INSERT INTO recipe_categories (group_id, name, parent_category_id, icon)
SELECT base.group_id, x.name, base.id, 'plate-wheat' FROM base
JOIN (VALUES('Kalt'),('Warm')) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Spezielles
WITH g AS (SELECT id FROM recipe_category_groups WHERE name = 'Spezielles')
INSERT INTO recipe_categories (group_id, name, icon)
SELECT g.id, x.name, 'star' FROM g
JOIN (VALUES
  ('Babynahrung'),('Camping'),('cross-cooking'),('Ernährungskonzepte'),('Festlich'),('Fingerfood'),('Geheimrezepte'),('Kinder'),('Party'),
  ('Raffiniert & preiswert'),('Resteverwertung'),('Saucen & Dips'),('Schnell und einfach'),('Studentenküche'),('Wursten')
) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Spezielles -> Ernährungskonzepte Unterkategorien
WITH base AS (
  SELECT c.id, c.group_id FROM recipe_categories c
  JOIN recipe_category_groups g ON g.id = c.group_id
  WHERE g.name = 'Spezielles' AND c.name = 'Ernährungskonzepte'
)
INSERT INTO recipe_categories (group_id, name, parent_category_id, icon)
SELECT base.group_id, x.name, base.id, 'seedling' FROM base
JOIN (VALUES('Diabetiker'),('Fettarm'),('Kalorienarm'),('Low fat'),('Trennkost'),('Vegan'),('Vegetarisch'),('Vollwert')) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Regional (Hauptregionen)
WITH g AS (SELECT id FROM recipe_category_groups WHERE name = 'Regional')
INSERT INTO recipe_categories (group_id, name, icon)
SELECT g.id, x.name, 'globe' FROM g
JOIN (VALUES
  ('Afrika'),('Amerika'),('Asien'),('Australien'),('Europa'),('Karibik & Exotik'),('Mittlerer und Naher Osten'),('Osteuropa')
) AS x(name) ON TRUE
ON CONFLICT (group_id, name) DO NOTHING;

-- Regional -> Unterregionen
WITH base AS (
  SELECT c.id, c.name, c.group_id
  FROM recipe_categories c JOIN recipe_category_groups g ON g.id = c.group_id
  WHERE g.name = 'Regional'
), europe AS (
  SELECT id, group_id FROM base WHERE name = 'Europa'
), africa AS (
  SELECT id, group_id FROM base WHERE name = 'Afrika'
), america AS (
  SELECT id, group_id FROM base WHERE name = 'Amerika'
), asia AS (
  SELECT id, group_id FROM base WHERE name = 'Asien'
)
INSERT INTO recipe_categories (group_id, name, parent_category_id, icon)
SELECT t.group_id, v.name, t.id, 'globe' FROM (
  SELECT 'Europa'::text AS parent, id, group_id FROM europe
  UNION ALL SELECT 'Afrika', id, group_id FROM africa
  UNION ALL SELECT 'Amerika', id, group_id FROM america
  UNION ALL SELECT 'Asien', id, group_id FROM asia
) t
JOIN (
  VALUES
  ('Europa','Belgien'),('Europa','Deutschland'),('Europa','Dänemark'),('Europa','Finnland'),('Europa','Frankreich'),('Europa','Griechenland'),('Europa','Großbritannien & Irland'),('Europa','Italien'),('Europa','Luxemburg'),('Europa','Malta'),('Europa','Niederlande'),('Europa','Norwegen'),('Europa','Polen'),('Europa','Portugal'),('Europa','Russland'),('Europa','Schweden'),('Europa','Schweiz'),('Europa','Spanien'),('Europa','Tschechien'),('Europa','Türkei'),('Europa','Ungarn'),('Europa','Weißrussland'),('Europa','Österreich'),
  ('Afrika','Marokko'),('Afrika','Südafrika'),('Afrika','Ägypten'),
  ('Amerika','Lateinamerika'),('Amerika','Mexico'),('Amerika','USA & Kanada'),
  ('Asien','Chinesisch'),('Asien','Indisch'),('Asien','Japanisch'),('Asien','Koreanisch'),('Asien','Thailand'),('Asien','Vietnam')
) v(parent, name) ON v.parent = t.parent
ON CONFLICT (group_id, name) DO NOTHING;

-- =====================================================
-- VIEWS - Convenient data access
-- =====================================================

-- View showing recipes with category details
CREATE VIEW recipes_with_details AS
SELECT 
  r.*,
  creator.email as creator_email,
  creator.raw_user_meta_data->>'full_name' as creator_name,
  COALESCE(json_agg(json_build_object('id', rc.id, 'name', rc.name, 'icon', rc.icon))
           FILTER (WHERE rc.id IS NOT NULL), '[]'::json) AS categories
FROM recipes r
LEFT JOIN auth.users creator ON r.created_by = creator.id
LEFT JOIN recipe_categories_map rcm ON rcm.recipe_id = r.id
LEFT JOIN recipe_categories rc ON rc.id = rcm.category_id
WHERE r.is_deleted = FALSE
GROUP BY r.id, creator.email, creator.raw_user_meta_data;

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

-- View showing recipe units mapped to grocery units
CREATE VIEW recipe_units_mapped_to_grocery_units AS
SELECT 
  ru.id as recipe_unit_id,
  ru.name as recipe_unit_name,
  ru.short_name as recipe_unit_short_name,
  gu.id as grocery_unit_id,
  gu.name as grocery_unit_name,
  gu.short_name as grocery_unit_short_name,
  rugum.conversion_factor,
  rugum.notes,
  rugum.created_at,
  rugum.updated_at
FROM recipe_units ru
LEFT JOIN recipe_units_to_grocery_units_map rugum ON ru.id = rugum.recipe_unit_id
LEFT JOIN grocery_units gu ON rugum.grocery_unit_id = gu.id
ORDER BY ru.name, gu.name;

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
-- STORAGE: PUBLIC BUCKET FOR ASSETS
-- =====================================================

-- Create a public bucket for publicly accessible assets (e.g., images)
INSERT INTO storage.buckets (id, name, public)
VALUES ('public-bucket', 'public-bucket', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Lesen für alle (falls noch nicht vorhanden)
CREATE POLICY "Public read for public-bucket"
ON storage.objects FOR SELECT
USING (bucket_id = 'public-bucket');

-- Upload nur für angemeldete Nutzer
CREATE POLICY "Authenticated users can upload public-bucket"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'public-bucket');

-- Eigene Dateien aktualisieren
CREATE POLICY "Users can update own public-bucket objects"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'public-bucket' AND owner = auth.uid())
WITH CHECK (bucket_id = 'public-bucket' AND owner = auth.uid());

-- Eigene Dateien löschen
CREATE POLICY "Users can delete own public-bucket objects"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'public-bucket' AND owner = auth.uid());

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
-- ✅ Recipe units with grocery units mapping for shopping list conversion
-- ✅ Row Level Security protecting all data
-- ✅ Helper functions for ingredient display and recipe management
-- ✅ Unit conversion functions for recipe-to-shopping-list workflow
-- ✅ Automatic timestamp management
-- ✅ Performance-optimized indexes
-- ✅ Convenient views for data access
-- ✅ Soft delete functionality
--
-- Next steps:
-- 1. Test the API endpoints
-- 2. Create frontend integration
-- 3. Add recipe search and filtering functionality
-- 4. Implement recipe-to-shopping-list conversion using unit mappings
-- ===================================================== 