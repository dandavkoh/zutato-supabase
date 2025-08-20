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
  WHEN 'Brot und Brötchen' THEN 1
  WHEN 'Cremes' THEN 2
  WHEN 'Eis' THEN 3
  WHEN 'Kekse & Plätzchen' THEN 4
  WHEN 'Konfiserie' THEN 5
  WHEN 'Kuchen' THEN 6
  WHEN 'Tarte/Quiche' THEN 7
  WHEN 'Torten' THEN 8
  WHEN 'Afrika' THEN 1
  WHEN 'Marokko' THEN 2
  WHEN 'Südafrika' THEN 3
  WHEN 'Ägypten' THEN 4
  WHEN 'Amerika' THEN 5
  WHEN 'Lateinamerika' THEN 6
  WHEN 'Mexico' THEN 7
  WHEN 'USA & Kanada' THEN 8
  WHEN 'Asien' THEN 9
  WHEN 'Chinesisch' THEN 10
  WHEN 'Indisch' THEN 11
  WHEN 'Japanisch' THEN 12
  WHEN 'Koreanisch' THEN 13
  WHEN 'Thailand' THEN 14
  WHEN 'Vietnam' THEN 15
  WHEN 'Australien' THEN 16
  WHEN 'Europa' THEN 17
  WHEN 'Belgien' THEN 18
  WHEN 'Deutschland' THEN 19
  WHEN 'Dänemark' THEN 20
  WHEN 'Finnland' THEN 21
  WHEN 'Frankreich' THEN 22
  WHEN 'Griechenland' THEN 23
  WHEN 'Großbritannien & Irland' THEN 24
  WHEN 'Italien' THEN 25
  WHEN 'Luxemburg' THEN 26
  WHEN 'Malta' THEN 27
  WHEN 'Niederlande' THEN 28
  WHEN 'Norwegen' THEN 29
  WHEN 'Polen' THEN 30
  WHEN 'Portugal' THEN 31
  WHEN 'Russland' THEN 32
  WHEN 'Schweden' THEN 33
  WHEN 'Schweiz' THEN 34
  WHEN 'Spanien' THEN 35
  WHEN 'Tschechien' THEN 36
  WHEN 'Türkei' THEN 37
  WHEN 'Ungarn' THEN 38
  WHEN 'Weißrussland' THEN 39
  WHEN 'Österreich' THEN 40
  WHEN 'Karibik & Exotik' THEN 41
  WHEN 'Mittlerer und Naher Osten' THEN 42
  WHEN 'Osteuropa' THEN 43
  WHEN 'Aufstrich' THEN 1
  WHEN 'Backen' THEN 2
  WHEN 'Beilage' THEN 3
  WHEN 'Brotspeise' THEN 4
  WHEN 'Eierspeise' THEN 5
  WHEN 'Eintopf' THEN 6
  WHEN 'Fisch' THEN 7
  WHEN 'Frucht' THEN 8
  WHEN 'Frühstück' THEN 9
  WHEN 'Gemüse' THEN 10
  WHEN 'Gewürze/Öl/Essig/Pasten' THEN 11
  WHEN 'Grundrezepte' THEN 12
  WHEN 'Haltbarmachen' THEN 13
  WHEN 'Krustentier & Muscheln' THEN 14
  WHEN 'Käse' THEN 15
  WHEN 'Mehlspeisen' THEN 16
  WHEN 'Methoden' THEN 17
  WHEN 'Auflauf' THEN 18
  WHEN 'Barbecue & Grill' THEN 19
  WHEN 'Blanchieren' THEN 20
  WHEN 'Braten' THEN 21
  WHEN 'Dünsten' THEN 22
  WHEN 'Flambieren' THEN 23
  WHEN 'Fondue' THEN 24
  WHEN 'Frittieren' THEN 25
  WHEN 'Kochen' THEN 26
  WHEN 'Marinieren' THEN 27
  WHEN 'Mikrowelle' THEN 28
  WHEN 'Molekularküche' THEN 29
  WHEN 'Römertopf' THEN 30
  WHEN 'Schmoren' THEN 31
  WHEN 'Wok' THEN 32
  WHEN 'Überbacken' THEN 33
  WHEN 'Pasta' THEN 34
  WHEN 'Saucen' THEN 35
  WHEN 'Snacks und kleine Gerichte' THEN 36
  WHEN 'Süßspeisen' THEN 37
  WHEN 'Bowle' THEN 1
  WHEN 'Cocktail' THEN 2
  WHEN 'Alkoholfrei' THEN 3
  WHEN 'Longdrink' THEN 4
  WHEN 'Kaffee, Tee & Kakao' THEN 5
  WHEN 'Likör' THEN 6
  WHEN 'Punsch' THEN 7
  WHEN 'Shake' THEN 8
  WHEN 'Frühling' THEN 1
  WHEN 'Halloween' THEN 2
  WHEN 'Herbst' THEN 3
  WHEN 'Ostern' THEN 4
  WHEN 'Silvester' THEN 5
  WHEN 'Sommer' THEN 6
  WHEN 'Weihnachten' THEN 7
  WHEN 'Winter' THEN 8
  WHEN 'Beilage' THEN 1
  WHEN 'Gemüse' THEN 2
  WHEN 'Hülsenfrüchte' THEN 3
  WHEN 'Kartoffeln' THEN 4
  WHEN 'Klöße' THEN 5
  WHEN 'Nudeln' THEN 6
  WHEN 'Reis/Getreide' THEN 7
  WHEN 'Dessert' THEN 8
  WHEN 'Frühstück' THEN 9
  WHEN 'Hauptspeise' THEN 10
  WHEN 'Eier' THEN 11
  WHEN 'Eintopf' THEN 12
  WHEN 'Fisch' THEN 13
  WHEN 'Geflügel' THEN 14
  WHEN 'Frühstück' THEN 9
  WHEN 'Hauptspeise' THEN 10
  WHEN 'Eier' THEN 11
  WHEN 'Eintopf' THEN 12
  WHEN 'Fisch' THEN 13
  WHEN 'Geflügel' THEN 14
  WHEN 'Gemüse' THEN 15
  WHEN 'Hülsenfrüchte' THEN 16
  WHEN 'Innereien' THEN 17
  WHEN 'Kartoffeln' THEN 18
  WHEN 'Krustentier & Muscheln' THEN 19
  WHEN 'Lamm & Ziege' THEN 20
  WHEN 'Pasta & Nudel' THEN 21
  WHEN 'Pilze' THEN 22
  WHEN 'Pizza' THEN 23
  WHEN 'Reis/Getreide' THEN 24
  WHEN 'Rind' THEN 25
  WHEN 'Schwein' THEN 26
  WHEN 'Wild & Kaninchen' THEN 27
  WHEN 'Salat' THEN 28
  WHEN 'Eier & Käse' THEN 29
  WHEN 'Fleisch & Wurst' THEN 30
  WHEN 'Früchte' THEN 31
  WHEN 'Gemüse' THEN 32
  WHEN 'Kartoffel' THEN 33
  WHEN 'Krustentier & Fisch' THEN 34
  WHEN 'Pilze' THEN 35
  WHEN 'Reis/Nudeln/Getrei' THEN 36
  WHEN 'Salatdressing' THEN 37
  WHEN 'Warme Salate' THEN 38
  WHEN 'Suppen' THEN 39
  WHEN 'Einlagen' THEN 40
  WHEN 'Gebundene' THEN 41
  WHEN 'Klare' THEN 42
  WHEN 'Spezial' THEN 43
  WHEN 'Vorspeisen' THEN 44
  WHEN 'Kalt' THEN 45
  WHEN 'Warm' THEN 46
  WHEN 'Babynahrung' THEN 1
  WHEN 'Camping' THEN 2
  WHEN 'cross-cooking' THEN 3
  WHEN 'Ernährungskonzepte' THEN 4
  WHEN 'Diabetiker' THEN 5
  WHEN 'Fettarm' THEN 6
  WHEN 'Kalorienarm' THEN 7
  WHEN 'Low fat' THEN 8
  WHEN 'Trennkost' THEN 9
  WHEN 'Vegan' THEN 10
  WHEN 'Vegetarisch' THEN 11
  WHEN 'Vollwert' THEN 12
  WHEN 'Festlich' THEN 13
  WHEN 'Fingerfood' THEN 14
  WHEN 'Geheimrezepte' THEN 15
  WHEN 'Kinder' THEN 16
  WHEN 'Party' THEN 17
  WHEN 'Raffiniert & preiswert' THEN 18
  WHEN 'Resteverwertung' THEN 19
  WHEN 'Saucen & Dips' THEN 20
  WHEN 'Schnell und einfach' THEN 21
  WHEN 'Studentenküche' THEN 22
  WHEN 'Wursten' THEN 23
  ELSE sort_order
END;