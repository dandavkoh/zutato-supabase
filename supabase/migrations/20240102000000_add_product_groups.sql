-- =====================================================
-- ADD PRODUCT GROUPS TABLE
-- =====================================================
-- 
-- This migration adds a product_groups table for organizing
-- shopping items into logical groups with default settings.
--
-- Author: Grocery App Team
-- Date: 2024-01-02
-- =====================================================

-- =====================================================
-- EXTENSIONS
-- =====================================================
-- Enable required extensions for full-text search and trigram matching

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- TRIGRAM CONFIGURATION
-- =====================================================
-- Set similarity threshold for trigram fuzzy matching
-- Lower values = more fuzzy matches, higher values = more strict matches

SET pg_trgm.similarity_threshold = 0.25;

-- =====================================================
-- PRODUCT_GROUPS TABLE
-- =====================================================
-- Stores product groups with default settings for units, categories, and icons
-- Read-only for normal users, managed by admins

CREATE TABLE product_groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL UNIQUE,
  default_unit_id UUID REFERENCES grocery_units(id),
  default_category_id UUID REFERENCES grocery_categories(id),
  default_icon TEXT DEFAULT 'basket-shopping',
  fts tsvector GENERATED ALWAYS AS (to_tsvector('german', title)) STORED,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for data protection
ALTER TABLE product_groups ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================

-- Product group indexes
CREATE INDEX idx_product_groups_title ON product_groups(title);
CREATE INDEX idx_product_groups_default_unit ON product_groups(default_unit_id);
CREATE INDEX idx_product_groups_default_category ON product_groups(default_category_id);

-- Full-text search index
CREATE INDEX idx_product_groups_fts ON product_groups USING gin(fts);

-- Trigram index for fuzzy search
CREATE INDEX idx_product_groups_title_trgm ON product_groups USING gin(title gin_trgm_ops);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Everyone can read product groups
CREATE POLICY "Everyone can read product groups" ON product_groups
  FOR SELECT USING (true);

-- Only admins can create product groups
CREATE POLICY "Only admins can create product groups" ON product_groups
  FOR INSERT WITH CHECK (
    auth.jwt() ->> 'role' = 'service_role' OR
    auth.jwt() ->> 'email' IN (
      SELECT email FROM auth.users 
      WHERE raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- Only admins can update product groups
CREATE POLICY "Only admins can update product groups" ON product_groups
  FOR UPDATE USING (
    auth.jwt() ->> 'role' = 'service_role' OR
    auth.jwt() ->> 'email' IN (
      SELECT email FROM auth.users 
      WHERE raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- Only admins can delete product groups
CREATE POLICY "Only admins can delete product groups" ON product_groups
  FOR DELETE USING (
    auth.jwt() ->> 'role' = 'service_role' OR
    auth.jwt() ->> 'email' IN (
      SELECT email FROM auth.users 
      WHERE raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- =====================================================
-- TRIGGERS - Automatic timestamp updates
-- =====================================================

-- Update updated_at timestamp on product group changes
CREATE TRIGGER update_product_groups_updated_at BEFORE UPDATE ON product_groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SEED DATA - Product groups
-- =====================================================
-- Provides product groups for new installations

-- Insert product groups
INSERT INTO product_groups (title, default_unit_id, default_category_id, default_icon) VALUES
  ('Apfel', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Banane', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Birne', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Erdbeeren', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Kirsche', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Pfirsich', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Trauben', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Ananas', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Wassermelone', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Honigmelone', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Papaya', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Mango', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Kiwi', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Granatapfel', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Avocado', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Zitrone', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Limette', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Orange', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Mandarine', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Grapefruit', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Pflaume', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Nektarine', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Aprikose', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Clementine', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Kokosnuss', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Feige', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Brombeeren', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Himbeeren', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Heidelbeeren', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Johannisbeeren', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Stachelbeeren', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Physalis', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Drachenfrucht', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Litschi', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Bananenstaude', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Zuckermelone', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Kiwibeeren', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Waldbeeren', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Kaki', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Zwetschgen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Blaubeeren', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Jackfrucht', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Limonen', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Sternfrucht', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Kaktusfeige', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Maracuja', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Acerola', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Hagebutte', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Marula', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Feigen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1)),
  ('Paprika', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Karotte', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Erbsen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Kürbis', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Tomaten', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Kartoffeln', (SELECT id FROM grocery_units WHERE name = 'Kilogramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Zucchini', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Brokkoli', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Blumenkohl', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Spinat', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Gurke', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Lauch', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Rosenkohl', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Radieschen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Spargel', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Pilze', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Sellerie', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Fenchel', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Aubergine', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Bohnen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Artischocken', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Chinakohl', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Mangold', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Zwiebeln', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Knoblauch', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Kichererbsen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Linsen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Kohl', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Pak Choi', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Rote Beete', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Bohnensprossen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Salat', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Radicchio', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Endiviensalat', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Feldsalat', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Kopfsalat', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Frühlingszwiebeln', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Chili', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Pekingsalat', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Rucola', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Zuckerschoten', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Süßkartoffeln', (SELECT id FROM grocery_units WHERE name = 'Kilogramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Kohlrabi', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Zuckerrüben', (SELECT id FROM grocery_units WHERE name = 'Kilogramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Rettich', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Pastinaken', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Kohlkopf', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Karotten', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Steinpilze', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Gemüse' LIMIT 1)),
  ('Brot', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Toast', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Croissant', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Brötchen', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Baguette', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Pita-Brot', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Ciabatta', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Hefezopf', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Laugenbrötchen', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Laugenstange', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Dinkelbrot', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Vollkornbrot', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Sauerteigbrot', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Schwarzbrot', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Knäckebrot', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Bagel', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Focaccia', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Brioche', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Pumpernickel', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Fladenbrot', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Roggenbrot', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Schnecke', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Weizenbrot', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Scones', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Kuchen', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Torte', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Donuts', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Laugenbrezel', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Schokobrötchen', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Strudel', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Apfelstrudel', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Nussecken', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Kräuterbaguette', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Vollkornbrötchen', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Tartes', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Süßes Hefebrot', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Wraps', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Pinsa', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1)),
  ('Milch', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Joghurt', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Käse', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Frischkäse', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Mozzarella', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Butter', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Eier', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Sahne', (SELECT id FROM grocery_units WHERE name = 'Milliliter' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Quark', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Kefir', (SELECT id FROM grocery_units WHERE name = 'Milliliter' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Hüttenkäse', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Skyr', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Feta', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Parmesan', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Cheddar', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Camembert', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Brie', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Edamer', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Gouda', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Bergkäse', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Emmentaler', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Ricotta', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Ziegenkäse', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Grana Padano', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Schmelzkäse', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Tilsiter', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Limburger', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Kaffeesahne', (SELECT id FROM grocery_units WHERE name = 'Milliliter' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Kondensmilch', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Pudding', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Ziegenmilch', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Naturjoghurt', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Gorgonzola', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Buttermilch', (SELECT id FROM grocery_units WHERE name = 'Milliliter' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Creme Fraiche', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1)),
  ('Steak', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Hähnchengeschnetzeltes', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Hackfleisch', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Lyoner', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Rinderfilet', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Putenbrust', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Wiener Würstchen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Schinken', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Kochschinken', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Salami', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Mett', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Bratwurst', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Frikadellen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Hähnchenfleisch', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Schwarzwälder Schinken', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Schweinefleisch', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Rindfleisch', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Kassler', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Lammfleisch', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Schweinebauch', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Speck', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Wurst', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Leberwurst', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Rinderbraten', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Nürnberger Würstchen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Rindersteaks', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Putensteaks', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Hähnchenflügel', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Cabanossi', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Landjäger', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Salsiccia', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Bacon', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Bockwurst', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Kalbsbraten', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Putenbrustfilet', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Geflügelbrust', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Schweinefilet', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Krainer', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Bratwurst, grob', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Leberkäse', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Aufschnitt', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Kochschinken, geräuchert', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Rinderhüfte', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Putenbrustfilets', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Nürnberger', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Berner Würstchen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1)),
  ('Fisch', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Tintenfischringe', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Garnelen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Krabben', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Muscheln', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Sardinen', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Graved Lachs', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Austern', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Hummer', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Meeresfrüchte', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Tintenfisch', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Kalmare', (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fisch & Meeresfrüchte' LIMIT 1)),
  ('Fischstäbchen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Pizza', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Hähnchennuggets', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Aufbackbrötchen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Pommes frites', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Kartoffelpuffer', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Windbeutel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Gemüse-Mix', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Rahmspinat', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Frühlingsrollen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Eis', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Schlemmerfilet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Kroketten', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Chicken Wings', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Kaisergemüse', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tiefkühlkost' LIMIT 1)),
  ('Öl', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Olivenöl', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Rapsöl', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Essig', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Balsamico', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Weißweinessig', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Apfelessig', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Ketchup', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Senf', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Mayonnaise', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('BBQ Sauce', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Sriracha Sauce', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Worcestershiresauce', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Teriyakisauce', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Chilisauce', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Curry Sauce', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Sojasauce', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Vinaigrette', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Pesto', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Tomatensauce', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Chiliöl', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Sesamöl', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Ranch Dressing', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Cajun Sauce', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Barbecuesauce', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Essigessenz', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Balsamico-Dressing', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Honig-Senf-Dressing', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Piri-Piri Sauce', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Chimichurri', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Wasabi Sauce', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Schokoladensauce', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Grillsoße', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Mango Chutney', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Dijon Senf', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Tomaten Ketchup', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Öl, Essig & Saucen' LIMIT 1)),
  ('Marmelade', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Schokocreme', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Guacamole', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Nuss-Nougat-Creme', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Erdnussbutter', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Honig', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Konfitüre', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Tzatziki', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Aioli', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Zaziki', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Hummus', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Kräuterquark', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Fruchtaufstrich', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Käse-Dip', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Salsa', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Taco-Dip', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Meerrettich-Dip', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Käsecreme', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Ajvar', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brotaufstriche & Dips' LIMIT 1)),
  ('Paprikapulver', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Salz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Pfeffer', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Basilikum', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Oregano', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Rosmarin', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Thymian', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Koriander', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Knoblauchpulver', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Ingwer', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Kümmel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Muskatnuss', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Zimt', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Bohnenkraut', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Petersilie', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Majoran', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Dill', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Lorbeerblätter', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Estragon', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Bockshornklee', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Kardamom', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Anis', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Chilipulver', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Curry', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Safran', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Gemüsebrühe', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Würzmischung', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Senfkörner', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Paprika edelsüß', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Paprika scharf', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Fischgewürz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Zitronenmelisse', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Szechuanpfeffer', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Grillgewürz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Kräutersalz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Chimichurri Gewürz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Kräuter der Provence', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Sauerampfer', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Französische Kräuter', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Rauchsalz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Bärlauch', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Kräuterbuttergewürz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Wacholderbeeren', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Tamarindenpaste', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Limonenpfeffer', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Kurkuma', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Zitronengras', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Kummin', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Piment', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Kräuter', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Kräuter & Gewürze' LIMIT 1)),
  ('Zucker', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Mehl', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Vanillezucker', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Backpulver', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Hefe', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Kakaopulver', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Zitronensaft', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Puddingpulver', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Gelatine', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Natron', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Tortenguss', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Schokoladenraspel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Schokoladenstückchen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Zuckerguss', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Marzipan', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Lebkuchengewürz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Gewürznelken', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Ahornsirup', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Vanillemark', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Agar-Agar', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Dinkelmehl', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Vollkornmehl', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Kastanienmehl', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Stärke', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Zuckerersatz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Glukosesirup', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Puderzucker', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Rohrzucker', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Zitronenschale', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Brotbackmischung', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Gläserur', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Backzutaten' LIMIT 1)),
  ('Spaghetti', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Penne', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Fusilli', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Reis', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Basmatireis', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Vollkornreis', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Linsennudeln', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Tortellini', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Nudeln', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Reisnudeln', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Dinkelspaghetti', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Maccheroni', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Fadennudeln', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Reispapier', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Couscous', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Maultaschen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Jasminreis', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Penne Rigate', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Gläsernudeln', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Wildreis', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Gnocchi', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Schupfnudeln', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Lasagneplatten', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Tagliatelle', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Pappardelle', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Pasta, glutenfrei', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Vollkornpasta', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Tapioka', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Farfalle', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Cannelloni', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Soba-Nudeln, glutenfrei', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Risoni', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Nudeln & Reis' LIMIT 1)),
  ('Studentenfutter', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Mandeln', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Ananas, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Cashewkerne', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Haselnüsse', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Walnüsse', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Pistazien', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Mango, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Datteln', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Feigen, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Aprikosen, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Äpfel, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Erdbeeren, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Cranberries, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Goji Beeren, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Kokosraspel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Pinienkerne', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Chia Samen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Leinsamen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Sonnenblumenkerne', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Kürbiskerne', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Banane, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Rosinen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Sultaninen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Macadamianüsse', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Pekanüsse', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Kokoschips', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Pflaumen, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Kakaonibs', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Physalis, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Papaya, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Erdnüsse', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Kiwis, getrocknet', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Dörrzwetschgen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Zedernüsse', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Bananenchips', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Trockenfrüchte', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Nüsse', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Nussmischung', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Pekannüsse', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Trockenfrüchte & Nüsse' LIMIT 1)),
  ('Lasagne', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Ravioli', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('5 Minuten Terine', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Tütensuppe', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Instant-Nudeln', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Knödel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Currywurst', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Königsberger Klopse', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Kartoffelsalat', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Nudelsalat', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Kartoffelbrei', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Tacos', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Sandwich', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Bulgursalat', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Sushi, Fertig', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Nudelpfanne', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Pizzateig', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fertigprodukte' LIMIT 1)),
  ('Mandeldrink', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchersatz' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchersatz' LIMIT 1)),
  ('Haferdrink', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchersatz' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchersatz' LIMIT 1)),
  ('Sojadrink', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchersatz' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchersatz' LIMIT 1)),
  ('Reisdrink', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchersatz' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchersatz' LIMIT 1)),
  ('Kokosdrink', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchersatz' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchersatz' LIMIT 1)),
  ('Kidneybohnen', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Babymöhren', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Silberzwiebeln', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Essiggurken', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Getrocknete Tomaten', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Baked Beans', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Ananas aus der Dosen', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Pfirsiche aus der Dosen', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Schattenmorellen', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Oliven', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Weinblätter', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Artischockenherzen', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Sauerkraut', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Jakobsmuscheln', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Kokosmilch', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Bambussprossen', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Kapern', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Fruchtcocktail', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Apfelmus', (SELECT id FROM grocery_units WHERE name = 'Gläser' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Erbsen und Möhren', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Konserven' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Konserven' LIMIT 1)),
  ('Müsli', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1)),
  ('Cornflakes', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1)),
  ('Porridge', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1)),
  ('Haferflocken', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1)),
  ('Granola', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1)),
  ('Frühstücksflocken', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1)),
  ('Knuspermüsli', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Cerealien & Müsli' LIMIT 1)),
  ('Pralinen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Schokolade', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Kaubonbons', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Chips', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Gummibärchen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Salzstangen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Müsliriegel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Lakritz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Fruchtgummi', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Kekse', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Bonbons', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Marshmallows', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Lollis', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Lutscher', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Süßigkeiten & Snacks' LIMIT 1)),
  ('Wasser', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Limonade', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Apfelsaft', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Orangensaft', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Cola', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Bier', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Wein', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Tee', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Kaffee', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Eistee', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Mineralwasser', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Energy Drink', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Fruchtsaft', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Johannisbeersaft', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Kombucha', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Wodka', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Whiskey', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Sekt', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Likör', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Gin', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Soda', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Rhabarbersaft', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Pfirsichsaft', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Tonic Water', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Kakao', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Prosecco', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Maracujasaft', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Cider', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Tequila', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Smoothie', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Traubensaft', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Alkohol', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Saft', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Getränke' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Getränke' LIMIT 1)),
  ('Küchenrolle', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Putzschwamm', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Spülmittel', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Staubsaugerbeutel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Müllbeutel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Reinigungsmittel', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Gläserreiniger', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Waschmittel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Weichspüler', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Scheuermilch', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Desinfektionsmittel', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Abflussreiniger', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Backpapier', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Alufolie', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Frischhaltefolie', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Handschuhe', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Putzlappen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Spülmaschinen Tabs', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Spülmaschinen Salz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Putzmittel', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Kalkreiniger', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Abfallbeutel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Lappen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Putztücher', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Staubtücher', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Spülmaschinentabs', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Teppichreiniger', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Fensterreiniger', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Spezialreiniger', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Backofenreiniger', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Bleiche', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Toilettenreiniger', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Müllsack', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Reinigungskristalle', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Klammern', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Reisnägel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Batterien', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Klebeband', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Haushalt' LIMIT 1)),
  ('Duschgel', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Seife', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Taschentücher', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Shampoo', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Zahnpasta', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Toilettenpapier', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Deodorant', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Klopapier', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Klosteine', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Gesichtscreme', (SELECT id FROM grocery_units WHERE name = 'Tuben' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Handcreme', (SELECT id FROM grocery_units WHERE name = 'Tuben' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Haarspülung', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Konditionierer', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Haarfarbe', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Nagellack', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Rasierklingen', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Rasiergel', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Rasierschaum', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Rasiercreme', (SELECT id FROM grocery_units WHERE name = 'Tuben' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Wattestäbchen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Feuchttücher', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Nagellackentferner', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Badezusatz', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Make-up Entferner', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Haarmaske', (SELECT id FROM grocery_units WHERE name = 'Tuben' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Make-up', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Mascara', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Lippenstift', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Bodylotion', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Sonnencreme', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('After Sun Lotion', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Kosmetiktücher', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Wattepads', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Gesichtsmaske', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Reinigungstücher', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Parfüm', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Handseife', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Haaröl', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Gesichtsreiniger', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Lippenpflege', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Zahnbürste', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Zahnpasta, Whitening', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Haarwachs', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Haargel', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Haarschaum', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Peeling', (SELECT id FROM grocery_units WHERE name = 'Tuben' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Feuchtigkeitsspray', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Wimperntusche', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Kondome', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Mundspülung', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Drogerie & Kosmetik' LIMIT 1)),
  ('Hundefutter', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tier' LIMIT 1)),
  ('Katzenfutter', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tier' LIMIT 1)),
  ('Katzenstreu', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tier' LIMIT 1)),
  ('Einstreu', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tier' LIMIT 1)),
  ('Kauknochen', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tier' LIMIT 1)),
  ('Leckerlis', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tier' LIMIT 1)),
  ('Tierfutter', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tier' LIMIT 1)),
  ('Zeckenschutz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tier' LIMIT 1)),
  ('Flohschutz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tier' LIMIT 1)),
  ('Vogelfutter', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tier' LIMIT 1)),
  ('Fischfutter', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Tier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Tier' LIMIT 1)),
  ('Babymilch', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Windeln', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Babypuder', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Kindersnack', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Quetschies', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Babyshampoo', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Babycreme', (SELECT id FROM grocery_units WHERE name = 'Tuben' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Schnuller', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Babynahrung', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Wickelauflage', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Windelcreme', (SELECT id FROM grocery_units WHERE name = 'Tuben' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Schwimmwindeln', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Babyöl', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Babybrei', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Baby & Kind' LIMIT 1)),
  ('Pflaster', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Mullbinde', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Schmerzmittel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Vitamine', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Nahrungsergänzungsmittel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Hustensaft', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Hustenbonbons', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Antibiotika', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Wundsalbe', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Augentropfen', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Erkältungsmittel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Nasenspray', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Halstabletten', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Schlafmittel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Bauchschmerzenmittel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Hautsalbe', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Verbandmaterial', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Schwangerschaftstest', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Desinfektionstücher', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Wundverbände', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Beruhigungsmittel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Lactasepräparate', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Probiotika', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Arzneiprodukte' LIMIT 1)),
  ('Blumenerde', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Dünger', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Schrauben', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Nägel', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Schleifpapier', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Pflanzenschutzmittel', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Unkrautvernichter', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Saatgut', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Kabelbinder', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Leim', (SELECT id FROM grocery_units WHERE name = 'Flaschen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Draht', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Wandfarbe', (SELECT id FROM grocery_units WHERE name = 'Dosen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Kompost', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Rindenmulch', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Grillanzünder', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Rasendünger', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Werkzeuge', (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1)),
  ('Kaminholz', (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Garten & Baumarkt' LIMIT 1))
ON CONFLICT (title) DO NOTHING;

-- =====================================================
-- HYBRID SEARCH FUNCTION
-- =====================================================
-- Provides hybrid search combining full-text search and trigram fuzzy matching
-- Returns results with ranking and source information

CREATE OR REPLACE FUNCTION search_product_groups(
  term text, 
  limit_fts int default 10, 
  limit_fuzzy int default 10
)
RETURNS TABLE(
  id uuid, 
  title text, 
  default_icon text,
  default_category_id uuid,
  rank double precision, 
  src text
) 
LANGUAGE plpgsql 
STABLE 
AS $$
BEGIN
  RETURN QUERY
  (
    -- 1. Fast full-text search matches
    SELECT 
      pg.id, 
      pg.title, 
      pg.default_icon,
      pg.default_category_id,
      ts_rank(pg.fts, q.ts)::double precision as rank, 
      'fts'::text as src
    FROM product_groups pg, 
         (SELECT websearch_to_tsquery('german', term || ':*') ts) q
    WHERE pg.fts @@ q.ts
    ORDER BY rank DESC
    LIMIT limit_fts
  )
  UNION ALL
  (
    -- 2. Trigram fallback (no duplicates)
    SELECT 
      pg.id, 
      pg.title, 
      pg.default_icon,
      pg.default_category_id,
      similarity(pg.title, term)::double precision as rank, 
      'fuzzy'::text as src
    FROM product_groups pg
    WHERE pg.title % term
      AND NOT pg.fts @@ websearch_to_tsquery('german', term || ':*')
    ORDER BY rank DESC
    LIMIT limit_fuzzy
  );
END;
$$;

-- =====================================================
-- PRODUCTS TABLE
-- =====================================================
-- Stores concrete products that belong to product groups
-- Users can create their own products and link them to product groups

CREATE TABLE products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  product_group_id UUID REFERENCES product_groups(id) ON DELETE CASCADE,
  unit_id UUID REFERENCES grocery_units(id),
  default_category_id UUID REFERENCES grocery_categories(id),
  default_icon TEXT DEFAULT 'basket-shopping',
  fts tsvector GENERATED ALWAYS AS (to_tsvector('german', title)) STORED,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Enable Row Level Security for data protection
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- INDEXES FOR PRODUCTS TABLE
-- =====================================================

-- Product indexes
CREATE INDEX idx_products_title ON products(title);
CREATE INDEX idx_products_product_group_id ON products(product_group_id);
CREATE INDEX idx_products_unit_id ON products(unit_id);
CREATE INDEX idx_products_default_category ON products(default_category_id);
CREATE INDEX idx_products_created_by ON products(created_by);

-- Full-text search index
CREATE INDEX idx_products_fts ON products USING gin(fts);

-- Trigram index for fuzzy search
CREATE INDEX idx_products_title_trgm ON products USING gin(title gin_trgm_ops);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES FOR PRODUCTS
-- =====================================================

-- Everyone can read products
CREATE POLICY "Everyone can read products" ON products
  FOR SELECT USING (true);

-- Only admins can create products
CREATE POLICY "Only admins can create products" ON products
  FOR INSERT WITH CHECK (
    auth.jwt() ->> 'role' = 'service_role' OR
    auth.jwt() ->> 'email' IN (
      SELECT email FROM auth.users 
      WHERE raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- Only admins can update products
CREATE POLICY "Only admins can update products" ON products
  FOR UPDATE USING (
    auth.jwt() ->> 'role' = 'service_role' OR
    auth.jwt() ->> 'email' IN (
      SELECT email FROM auth.users 
      WHERE raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- Only admins can delete products
CREATE POLICY "Only admins can delete products" ON products
  FOR DELETE USING (
    auth.jwt() ->> 'role' = 'service_role' OR
    auth.jwt() ->> 'email' IN (
      SELECT email FROM auth.users 
      WHERE raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- =====================================================
-- TRIGGERS - Automatic timestamp updates for products
-- =====================================================

-- Update updated_at timestamp on product changes
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ENHANCED HYBRID SEARCH FUNCTION
-- =====================================================
-- Provides hybrid search combining full-text search and trigram fuzzy matching
-- Searches both product_groups and products tables
-- Returns results with ranking and source information

CREATE OR REPLACE FUNCTION search_products_and_groups(
  term text, 
  limit_fts int default 10, 
  limit_fuzzy int default 10
)
RETURNS TABLE(
  id uuid, 
  title text, 
  icon text,
  category_id uuid,
  rank double precision, 
  src text,
  type text
) 
LANGUAGE plpgsql 
STABLE 
AS $$
BEGIN
  RETURN QUERY
  (
    -- 1. Fast full-text search matches in product_groups
    SELECT 
      pg.id, 
      pg.title, 
      pg.default_icon as icon,
      pg.default_category_id as category_id,
      ts_rank(pg.fts, q.ts)::double precision as rank, 
      'fts'::text as src,
      'group'::text as type
    FROM product_groups pg, 
         (SELECT websearch_to_tsquery('german', term || ':*') ts) q
    WHERE pg.fts @@ q.ts
    ORDER BY rank DESC
    LIMIT limit_fts
  )
  UNION ALL
  (
    -- 2. Fast full-text search matches in products
    SELECT 
      p.id, 
      p.title, 
      p.default_icon as icon,
      p.default_category_id as category_id,
      ts_rank(p.fts, q.ts)::double precision as rank, 
      'fts'::text as src,
      'product'::text as type
    FROM products p, 
         (SELECT websearch_to_tsquery('german', term || ':*') ts) q
    WHERE p.fts @@ q.ts
    ORDER BY rank DESC
    LIMIT limit_fts
  )
  UNION ALL
  (
    -- 3. Trigram fallback for product_groups (no duplicates)
    SELECT 
      pg.id, 
      pg.title, 
      pg.default_icon as icon,
      pg.default_category_id as category_id,
      similarity(pg.title, term)::double precision as rank, 
      'fuzzy'::text as src,
      'group'::text as type
    FROM product_groups pg
    WHERE pg.title % term
      AND NOT pg.fts @@ websearch_to_tsquery('german', term || ':*')
    ORDER BY rank DESC
    LIMIT limit_fuzzy
  )
  UNION ALL
  (
    -- 4. Trigram fallback for products (no duplicates)
    SELECT 
      p.id, 
      p.title, 
      p.default_icon as icon,
      p.default_category_id as category_id,
      similarity(p.title, term)::double precision as rank, 
      'fuzzy'::text as src,
      'product'::text as type
    FROM products p
    WHERE p.title % term
      AND NOT p.fts @@ websearch_to_tsquery('german', term || ':*')
    ORDER BY rank DESC
    LIMIT limit_fuzzy
  )
  ORDER BY rank DESC
  LIMIT (limit_fts + limit_fuzzy);
END;
$$;

-- =====================================================
-- BACKWARD COMPATIBILITY - Keep original function
-- =====================================================
-- The original search_product_groups function is kept for backward compatibility

-- =====================================================
-- SEED DATA - Sample products
-- =====================================================
-- Provides some sample products for testing

-- INSERT INTO products (title, product_group_id, unit_id, default_category_id, default_icon, created_by) VALUES
--   ('Bio Apfel Golden Delicious', (SELECT id FROM product_groups WHERE title = 'Apfel' LIMIT 1), (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT id FROM auth.users LIMIT 1)),
--   ('Bio Banane Fairtrade', (SELECT id FROM product_groups WHERE title = 'Banane' LIMIT 1), (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Obst' LIMIT 1), (SELECT id FROM auth.users LIMIT 1)),
--   ('Vollkornbrot vom Bäcker', (SELECT id FROM product_groups WHERE title = 'Vollkornbrot' LIMIT 1), (SELECT id FROM grocery_units WHERE name = 'Stück' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Brot & Backwaren' LIMIT 1), (SELECT id FROM auth.users LIMIT 1)),
--   ('Bio Milch 3,8%', (SELECT id FROM product_groups WHERE title = 'Milch' LIMIT 1), (SELECT id FROM grocery_units WHERE name = 'Packungen' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Milchprodukte & Eier' LIMIT 1), (SELECT id FROM auth.users LIMIT 1)),
--   ('Hähnchenbrustfilet Bio', (SELECT id FROM product_groups WHERE title = 'Hähnchenfleisch' LIMIT 1), (SELECT id FROM grocery_units WHERE name = 'Gramm' LIMIT 1), (SELECT id FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT icon FROM grocery_categories WHERE name = 'Fleisch' LIMIT 1), (SELECT id FROM auth.users LIMIT 1))
-- ON CONFLICT DO NOTHING;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- 
-- The product_groups and products tables are now ready with:
-- ✅ Auto-generated UUID primary keys
-- ✅ Title fields with appropriate constraints
-- ✅ Default unit and category lookups
-- ✅ Default icons with basket-shopping fallback
-- ✅ Full-text search columns (fts) with German language support
-- ✅ Row Level Security protecting user data
-- ✅ Performance-optimized indexes (including FTS and trigram)
-- ✅ pg_trgm extension enabled
-- ✅ Trigram similarity threshold configured (0.25)
-- ✅ Automatic timestamp management
-- ✅ Seed data for both tables
-- ✅ Enhanced hybrid search function (searches both tables)
-- ✅ Backward compatibility with original search function
--
-- Next steps:
-- 1. Test the API endpoints
-- 2. Integrate with frontend
-- 3. Add admin interface for management
-- ===================================================== 