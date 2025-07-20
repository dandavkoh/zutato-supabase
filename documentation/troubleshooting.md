# Troubleshooting Guide

## 🚨 Häufige Probleme und Lösungen

### Supabase-Probleme

#### 1. Supabase startet nicht

**Problem:** `npx supabase start` schlägt fehl

**Mögliche Ursachen:**
- Docker läuft nicht
- Ports sind bereits belegt
- Unzureichende Systemressourcen

**Lösungen:**
```bash
# 1. Docker Status prüfen
docker --version
docker ps

# 2. Docker Desktop starten (falls nicht läuft)

# 3. Ports prüfen
lsof -i :54321
lsof -i :54322
lsof -i :54323

# 4. Supabase stoppen und neu starten
npx supabase stop
npx supabase start

# 5. System-Ressourcen prüfen
# Mindestens 4GB RAM und 2GB freier Speicherplatz
```

#### 2. Datenbank-Verbindung fehlschlägt

**Problem:** `npx supabase db reset` schlägt fehl

**Lösungen:**
```bash
# 1. Supabase Status prüfen
npx supabase status

# 2. Logs anzeigen
npx supabase logs --service postgres

# 3. Datenbank zurücksetzen
npx supabase db reset

# 4. Bei hartnäckigen Problemen: Komplett neu starten
npx supabase stop
docker system prune -f
npx supabase start
```

#### 3. Migrationen werden nicht angewendet

**Problem:** Schema-Änderungen werden nicht übernommen

**Lösungen:**
```bash
# 1. Migration-Status prüfen
npx supabase migration list

# 2. Alle Migrationen neu ausführen
npx supabase db reset

# 3. Neue Migration erstellen
npx supabase migration new fix_schema

# 4. Migration manuell ausführen
npx supabase db push
```

### Frontend-Probleme

#### 1. Supabase Client Verbindung

**Problem:** `Failed to fetch` oder CORS-Fehler

**Lösungen:**
```javascript
// 1. Korrekte URL und Key verwenden
const supabase = createClient(
  'http://127.0.0.1:54321', // Lokal
  'your-anon-key'
)

// 2. Keys prüfen
npx supabase status

// 3. CORS-Einstellungen prüfen
// Supabase Studio -> Settings -> API
```

#### 2. Authentication-Probleme

**Problem:** Benutzer kann sich nicht registrieren/anmelden

**Debugging:**
```bash
# 1. Supabase Logs prüfen
npx supabase logs --service auth

# 2. Email-Konfiguration prüfen
# Supabase Studio -> Authentication -> Settings
```

**Lösungen:**
```sql
-- 1. Benutzer manuell löschen (nur für Tests)
DELETE FROM auth.users WHERE email = 'test@example.com';

-- 2. Email-Bestätigung deaktivieren (nur für Tests)
-- Supabase Studio -> Authentication -> Settings -> Email Confirmations
```

#### 3. RLS-Policies funktionieren nicht

**Problem:** Benutzer können Daten nicht sehen/bearbeiten

**Debugging:**
```sql
-- 1. RLS Status prüfen
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- 2. Policies anzeigen
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE schemaname = 'public';

-- 3. Aktuellen Benutzer prüfen
SELECT auth.uid();

-- 4. Test-Query mit RLS
SELECT * FROM lists WHERE id = 'test-uuid';
```

**Lösungen:**
```sql
-- 1. RLS für Tabelle aktivieren
ALTER TABLE lists ENABLE ROW LEVEL SECURITY;

-- 2. Policy erstellen
CREATE POLICY "Users can view their lists" ON lists
  FOR SELECT USING (auth.uid() = created_by);

-- 3. Policy testen
SELECT * FROM lists;
```

### Datenbank-Probleme

#### 1. Foreign Key Constraints verletzt

**Problem:** `insert or update on table "shopping_items" violates foreign key constraint`

**Lösungen:**
```sql
-- 1. Referenzierte Daten prüfen
SELECT * FROM lists WHERE id = 'referenced-uuid';
SELECT * FROM categories WHERE id = 'referenced-uuid';
SELECT * FROM units WHERE id = 'referenced-uuid';

-- 2. Fehlende Daten einfügen
INSERT INTO categories (name, icon) VALUES ('Neue Kategorie', 'icon');

-- 3. Constraint temporär deaktivieren (nur für Tests)
ALTER TABLE shopping_items DISABLE TRIGGER ALL;
-- Daten einfügen
ALTER TABLE shopping_items ENABLE TRIGGER ALL;
```

#### 2. Performance-Probleme

**Problem:** Queries sind langsam

**Debugging:**
```sql
-- 1. Langsame Queries finden
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- 2. Index-Usage prüfen
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- 3. Query plan analysieren
EXPLAIN ANALYZE SELECT * FROM shopping_items WHERE list_id = 'uuid';
```

**Lösungen:**
```sql
-- 1. Fehlende Indexes erstellen
CREATE INDEX CONCURRENTLY idx_shopping_items_list_id 
ON shopping_items(list_id);

-- 2. Composite Indexes für häufige Queries
CREATE INDEX CONCURRENTLY idx_shopping_items_list_completed 
ON shopping_items(list_id, is_completed) 
WHERE is_deleted = FALSE;

-- 3. Statistiken aktualisieren
ANALYZE shopping_items;
```

### API-Probleme

#### 1. 404-Fehler

**Problem:** Endpoint nicht gefunden

**Debugging:**
```bash
# 1. Supabase Status prüfen
npx supabase status

# 2. API URL prüfen
curl http://127.0.0.1:54321/rest/v1/

# 3. Tabellen-Liste prüfen
curl http://127.0.0.1:54321/rest/v1/ \
  -H "apikey: your-anon-key"
```

**Lösungen:**
```bash
# 1. Supabase neu starten
npx supabase restart

# 2. Migrationen ausführen
npx supabase db reset

# 3. RLS-Policies prüfen
# Supabase Studio -> Authentication -> Policies
```

#### 2. 401/403-Fehler

**Problem:** Unauthorized oder Forbidden

**Debugging:**
```javascript
// 1. Token prüfen
const { data: { user } } = await supabase.auth.getUser()
console.log('Current user:', user)

// 2. RLS-Policies prüfen
// Supabase Studio -> Authentication -> Policies

// 3. API Key prüfen
console.log('Using URL:', supabase.supabaseUrl)
console.log('Using Key:', supabase.supabaseKey)
```

**Lösungen:**
```javascript
// 1. Korrekte Authentifizierung
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password123'
})

// 2. Token-Refresh
const { data: { session } } = await supabase.auth.getSession()
if (session) {
  // Token ist gültig
}
```

### Frontend-Integration-Probleme

#### 1. CORS-Fehler im Browser

**Problem:** Browser blockiert Cross-Origin Requests

**Lösungen:**
```javascript
// 1. Korrekte Supabase URL verwenden
const supabase = createClient(
  'http://127.0.0.1:54321', // Lokal
  'your-anon-key'
)

// 2. Supabase Studio -> Settings -> API
// Site URL: http://localhost:3000 (Frontend URL)
```

#### 2. Token-Management

**Problem:** Token wird nicht korrekt gespeichert/übertragen

**Lösungen:**
```javascript
// 1. Session-Status überwachen
supabase.auth.onAuthStateChange((event, session) => {
  console.log('Auth state:', event, session?.user?.email)
})

// 2. Automatische Token-Verwaltung
const supabase = createClient(url, anonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
})

// 3. Token-Expiry prüfen
const isTokenExpired = (token) => {
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.exp * 1000 < Date.now();
  } catch {
    return true;
  }
};
```

## 🔧 Debug-Tools

### 1. Supabase Studio
**URL:** http://127.0.0.1:54323

**Features:**
- **Table Editor**: Tabellen und Daten anzeigen/bearbeiten
- **SQL Editor**: SQL-Abfragen ausführen
- **Authentication**: Benutzer verwalten
- **Storage**: Dateien verwalten
- **Edge Functions**: Serverless Functions
- **Logs**: System-Logs anzeigen

### 2. Database Tools

#### DBeaver
```bash
# Verbindungsdaten:
Host: 127.0.0.1
Port: 54322
Database: postgres
Username: postgres
Password: postgres
```

#### pgAdmin
```bash
# Gleiche Verbindungsdaten wie DBeaver
```

### 3. API Testing

#### Postman
```bash
# Collection erstellen:
Base URL: http://127.0.0.1:54321
Headers:
  apikey: your-anon-key
  Authorization: Bearer your-token
```

#### cURL
```bash
# Beispiel-Requests
curl -X GET http://127.0.0.1:54321/rest/v1/
curl -X POST http://127.0.0.1:54321/auth/v1/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### 4. Logging

#### Supabase Logs
```bash
# Alle Logs
npx supabase logs

# Spezifische Services
npx supabase logs --service postgres
npx supabase logs --service api
npx supabase logs --service auth

# Echtzeit-Logs
npx supabase logs --follow
```

#### Frontend Logs
```javascript
// Browser-Konsole
console.log('Supabase client:', supabase)

// Network Tab
// Prüfe Requests zu Supabase URLs
```

## 🚨 Notfall-Lösungen

### 1. Kompletter Reset
```bash
# Alles zurücksetzen
npx supabase stop
docker system prune -f
rm -rf supabase/.temp
npx supabase start
npx supabase db reset
```

### 2. Datenbank-Backup/Restore
```bash
# Backup erstellen
npx supabase db dump --file backup.sql

# Restore
npx supabase db reset
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" < backup.sql
```

### 3. Frontend Reset
```bash
# Node modules löschen und neu installieren
rm -rf node_modules package-lock.json
npm install

# Supabase Client neu installieren
npm install @supabase/supabase-js
```

## 📞 Support

### 1. Dokumentation
- [Supabase Docs](https://supabase.com/docs)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Supabase JavaScript Client](https://supabase.com/docs/reference/javascript)

### 2. Community
- [Supabase Discord](https://discord.supabase.com/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/supabase)
- [GitHub Issues](https://github.com/supabase/supabase/issues)

### 3. Debug-Checkliste
- [ ] Docker läuft
- [ ] Supabase Services sind aktiv
- [ ] Environment Variables sind gesetzt
- [ ] Dependencies sind installiert
- [ ] Ports sind frei
- [ ] Logs zeigen keine Fehler
- [ ] Datenbank-Schema ist korrekt
- [ ] RLS-Policies sind aktiviert
- [ ] JWT-Token ist gültig
- [ ] CORS ist konfiguriert
- [ ] Supabase Client ist korrekt initialisiert 