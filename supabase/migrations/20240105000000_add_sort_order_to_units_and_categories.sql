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

-- Set sort orders based on seeded display order

-- Grocery units
UPDATE grocery_units SET sort_order = CASE name
  WHEN 'Stück' THEN 1
  WHEN 'Milliliter' THEN 2
  WHEN 'Liter' THEN 3
  WHEN 'Gramm' THEN 4
  WHEN 'Kilogramm' THEN 5
  WHEN 'Packungen' THEN 6
  WHEN 'Flaschen' THEN 7
  WHEN 'Kästen' THEN 8
  WHEN 'Boxen' THEN 9
  WHEN 'Gläser' THEN 10
  WHEN 'Dosen' THEN 11
  WHEN 'Bund' THEN 12
  WHEN 'Tuben' THEN 13
  ELSE sort_order
END;

-- Recipe units
UPDATE recipe_units SET sort_order = CASE name
  WHEN 'Stück' THEN 1
  WHEN 'Milliliter' THEN 2
  WHEN 'Liter' THEN 3
  WHEN 'Gramm' THEN 4
  WHEN 'Kilogramm' THEN 5
  WHEN 'Packungen' THEN 6
  WHEN 'Flaschen' THEN 7
  WHEN 'Kästen' THEN 8
  WHEN 'Boxen' THEN 9
  WHEN 'Gläser' THEN 10
  WHEN 'Dosen' THEN 11
  WHEN 'Bund' THEN 12
  WHEN 'Tuben' THEN 13
  ELSE sort_order
END;

-- Grocery categories
UPDATE grocery_categories SET sort_order = CASE name
  WHEN 'Obst' THEN 1
  WHEN 'Gemüse' THEN 2
  WHEN 'Brot & Backwaren' THEN 3
  WHEN 'Milchprodukte & Eier' THEN 4
  WHEN 'Fleisch' THEN 5
  WHEN 'Fisch & Meeresfrüchte' THEN 6
  WHEN 'Tiefkühlkost' THEN 7
  WHEN 'Öl, Essig & Saucen' THEN 8
  WHEN 'Brotaufstriche & Dips' THEN 9
  WHEN 'Kräuter & Gewürze' THEN 10
  WHEN 'Backzutaten' THEN 11
  WHEN 'Nudeln & Reis' THEN 12
  WHEN 'Trockenfrüchte & Nüsse' THEN 13
  WHEN 'Fertigprodukte' THEN 14
  WHEN 'Milchersatz' THEN 15
  WHEN 'Konserven' THEN 16
  WHEN 'Cerealien & Müsli' THEN 17
  WHEN 'Süßigkeiten & Snacks' THEN 18
  WHEN 'Getränke' THEN 19
  WHEN 'Haushalt' THEN 20
  WHEN 'Drogerie & Kosmetik' THEN 21
  WHEN 'Tier' THEN 22
  WHEN 'Baby & Kind' THEN 23
  WHEN 'Arzneiprodukte' THEN 24
  WHEN 'Garten & Baumarkt' THEN 25
  ELSE sort_order
END;

-- Recipe categories
UPDATE recipe_categories SET sort_order = CASE name
  WHEN 'Hauptspeise' THEN 1
  WHEN 'Vorspeise' THEN 2
  WHEN 'Suppe' THEN 3
  WHEN 'Salat' THEN 4
  WHEN 'Beilage' THEN 5
  WHEN 'Dessert' THEN 6
  WHEN 'Kuchen' THEN 7
  WHEN 'Brot & Gebäck' THEN 8
  WHEN 'Frühstück' THEN 9
  WHEN 'Snack' THEN 10
  WHEN 'Getränk' THEN 11
  WHEN 'Likör' THEN 12
  WHEN 'Smoothie' THEN 13
  WHEN 'Dip & Sauce' THEN 14
  WHEN 'Marmelade & Konfitüre' THEN 15
  WHEN 'Eingelegtes' THEN 16
  WHEN 'Weihnachtsgebäck' THEN 17
  WHEN 'Ostergebäck' THEN 18
  WHEN 'Party & Buffet' THEN 19
  WHEN 'Vegetarisch' THEN 20
  WHEN 'Vegan' THEN 21
  WHEN 'Glutenfrei' THEN 22
  WHEN 'Laktosefrei' THEN 23
  WHEN 'Low Carb' THEN 24
  WHEN 'Keto' THEN 25
  WHEN 'Diät' THEN 26
  WHEN 'Kinderfreundlich' THEN 27
  WHEN 'Schnell & Einfach' THEN 28
  WHEN 'Slow Food' THEN 29
  WHEN 'Grillen' THEN 30
  WHEN 'Picknick' THEN 31
  WHEN 'Festtagsmenü' THEN 32
  WHEN 'International' THEN 33
  WHEN 'Regionale Küche' THEN 34
  WHEN 'Hausmannskost' THEN 35
  WHEN 'Gourmet' THEN 36
  WHEN 'Basisrezepte' THEN 37
  WHEN 'Resteverwertung' THEN 38
  ELSE sort_order
END;