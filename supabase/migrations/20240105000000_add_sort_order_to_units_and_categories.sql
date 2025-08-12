-- =====================================================
-- ADD SORT ORDER TO UNITS AND CATEGORIES
-- =====================================================
-- Adds a numeric sort field to support manual ordering in UIs
-- Tables: grocery_units, grocery_categories, recipe_units, recipe_categories
--
-- Author: Grocery App Team
-- Date: 2024-01-05
-- =====================================================

-- Add sort_order columns
ALTER TABLE grocery_units ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;
ALTER TABLE grocery_categories ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;
ALTER TABLE recipe_units ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;
ALTER TABLE recipe_categories ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;

-- Indexes for sorting queries
CREATE INDEX idx_grocery_units_sort_order ON grocery_units(sort_order);
CREATE INDEX idx_grocery_categories_sort_order ON grocery_categories(sort_order);
CREATE INDEX idx_recipe_units_sort_order ON recipe_units(sort_order);
CREATE INDEX idx_recipe_categories_sort_order ON recipe_categories(sort_order);