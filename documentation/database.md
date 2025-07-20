# Database Guide

## 🗄️ Datenbankschema

### Übersicht

Das Grocery App Schema besteht aus 5 Haupttabellen:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│      lists      │    │   list_members   │    │   categories    │
├─────────────────┤    ├──────────────────┤    ├─────────────────┤
│ id (UUID)       │    │ id (UUID)        │    │ id (UUID)       │
│ name (TEXT)     │    │ list_id (UUID)   │    │ name (TEXT)     │
│ description     │    │ user_id (UUID)   │    │ icon (TEXT)     │
│ created_by      │    │ role (TEXT)      │    │ created_at      │
│ created_at      │    │ invited_by       │    │ updated_at      │
│ updated_at      │    │ invited_at       │    └─────────────────┘
│ is_deleted      │    │ accepted_at      │
│ deleted_at      │    └──────────────────┘    ┌─────────────────┐
│ deleted_by      │                            │      units      │
└─────────────────┘                            ├─────────────────┤
                                               │ id (UUID)       │
                                               │ name (TEXT)     │
                                               │ short_name      │
                                               │ created_at      │
                                               │ updated_at      │
                                               └─────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      shopping_items                             │
├─────────────────────────────────────────────────────────────────┤
│ id (UUID)                                                       │
│ list_id (UUID) -> lists.id                                      │
│ name (TEXT)                                                     │
│ quantity (DECIMAL)                                              │
│ unit_id (UUID) -> units.id                                      │
│ category_id (UUID) -> categories.id                             │
│ notes (TEXT)                                                    │
│ is_completed (BOOLEAN)                                          │
│ completed_at (TIMESTAMP)                                        │
│ completed_by (UUID) -> auth.users.id                            │
│ created_by (UUID) -> auth.users.id                              │
│ created_at (TIMESTAMP)                                          │
│ updated_at (TIMESTAMP)                                          │
│ is_deleted (BOOLEAN)                                            │
│ deleted_at (TIMESTAMP)                                          │
│ deleted_by (UUID) -> auth.users.id                              │
└─────────────────────────────────────────────────────────────────┘
```

### Tabellen-Details

#### 1. `lists` - Einkaufslisten
```sql
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
```

#### 2. `list_members` - Listen-Mitglieder
```sql
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
```

#### 3. `categories` - Produktkategorien
```sql
CREATE TABLE categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT DEFAULT 'basket-shopping',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 4. `units` - Maßeinheiten
```sql
CREATE TABLE units (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  short_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 5. `shopping_items` - Einkaufsartikel
```sql
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
```

## 🔒 Row Level Security (RLS)

### Übersicht
Alle Tabellen haben RLS aktiviert. Dies bedeutet, dass Benutzer nur auf Daten zugreifen können, für die sie berechtigt sind.

### Policies

#### Lists Policies
```sql
-- Benutzer können Listen sehen, in denen sie Mitglied sind
CREATE POLICY "Users can view lists they are members of" ON lists
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM list_members 
      WHERE list_id = lists.id 
      AND user_id = auth.uid()
    )
  );

-- Benutzer können Listen erstellen
CREATE POLICY "Users can create lists" ON lists
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Benutzer können Listen bearbeiten, die sie besitzen oder für die sie Editor-Rechte haben
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
```

#### List Members Policies
```sql
-- Benutzer können Mitglieder von Listen sehen, in denen sie Mitglied sind
CREATE POLICY "Users can view list members" ON list_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM list_members lm2
      WHERE lm2.list_id = list_members.list_id 
      AND lm2.user_id = auth.uid()
    )
  );

-- Listen-Besitzer können Mitglieder hinzufügen
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
```

#### Shopping Items Policies
```sql
-- Benutzer können Artikel in Listen sehen, in denen sie Mitglied sind
CREATE POLICY "Users can view shopping items in their lists" ON shopping_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM list_members 
      WHERE list_id = shopping_items.list_id 
      AND user_id = auth.uid()
    )
  );

-- Benutzer können Artikel in Listen erstellen, in denen sie Mitglied sind
CREATE POLICY "Users can create shopping items in their lists" ON shopping_items
  FOR INSERT WITH CHECK (
    auth.uid() = created_by AND
    EXISTS (
      SELECT 1 FROM list_members 
      WHERE list_id = shopping_items.list_id 
      AND user_id = auth.uid()
    )
  );
```

## 📊 Views

### `lists_with_member_count`
Zeigt Listen mit der Anzahl der Mitglieder an:
```sql
CREATE VIEW lists_with_member_count AS
SELECT 
  l.*,
  COUNT(lm.user_id) as member_count
FROM lists l
LEFT JOIN list_members lm ON l.id = lm.list_id
WHERE l.is_deleted = FALSE
GROUP BY l.id;
```

### `shopping_items_with_details`
Zeigt Einkaufsartikel mit Kategorie- und Einheiten-Informationen:
```sql
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
```

## 🔧 Funktionen

### Soft Delete Funktionen

#### `soft_delete_list(list_uuid UUID)`
```sql
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
```

#### `soft_delete_shopping_item(item_uuid UUID)`
```sql
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
```

### Trigger Funktionen

#### `update_updated_at_column()`
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## 📈 Indexes

### Performance-Optimierung
```sql
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
```

## 🌱 Seed Data

### Kategorien
```sql
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
```

### Maßeinheiten
```sql
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
```

## 🔄 Migrationen

### Migration erstellen
```bash
npx supabase migration new migration_name
```

### Migration ausführen
```bash
# Alle Migrationen
npx supabase db reset

# Nur neue Migrationen
npx supabase db push
```

### Migration Status
```bash
npx supabase migration list
```

## 💾 Backup und Restore

### Backup erstellen
```bash
# Lokale Datenbank
npx supabase db dump --file backup.sql

# Cloud-Datenbank
pg_dump "postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres" > backup.sql
```

### Restore
```bash
# Lokale Datenbank
npx supabase db reset
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" < backup.sql

# Cloud-Datenbank
psql "postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres" < backup.sql
```

## 🔍 Nützliche Queries

### Listen eines Benutzers
```sql
SELECT l.*, COUNT(lm.user_id) as member_count
FROM lists l
LEFT JOIN list_members lm ON l.id = lm.list_id
WHERE l.is_deleted = FALSE
AND EXISTS (
  SELECT 1 FROM list_members 
  WHERE list_id = l.id 
  AND user_id = auth.uid()
)
GROUP BY l.id
ORDER BY l.created_at DESC;
```

### Einkaufsartikel einer Liste
```sql
SELECT 
  si.*,
  c.name as category_name,
  u.name as unit_name
FROM shopping_items si
LEFT JOIN categories c ON si.category_id = c.id
LEFT JOIN units u ON si.unit_id = u.id
WHERE si.list_id = 'list-uuid'
AND si.is_deleted = FALSE
ORDER BY si.created_at DESC;
```

### Mitglieder einer Liste
```sql
SELECT 
  lm.*,
  u.email,
  u.created_at as user_created_at
FROM list_members lm
JOIN auth.users u ON lm.user_id = u.id
WHERE lm.list_id = 'list-uuid'
ORDER BY lm.role, lm.invited_at;
```

## 🚨 Troubleshooting

### RLS-Probleme
```sql
-- RLS Status prüfen
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Policies anzeigen
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE schemaname = 'public';
```

### Performance-Probleme
```sql
-- Langsame Queries finden
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- Index-Usage prüfen
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

## 🔗 Nützliche Links

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Supabase Database Guide](https://supabase.com/docs/guides/database)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Performance Tuning](https://www.postgresql.org/docs/current/performance-tips.html) 