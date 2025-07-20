# Deployment Guide

## 🌐 Von Lokal zu Produktiv

### Übersicht
Dieser Guide erklärt, wie du dein lokales Supabase-Projekt in die Produktionsumgebung überführst.

## 🚀 Supabase Cloud Setup

### 1. Supabase Cloud Projekt erstellen

1. **Gehe zu [supabase.com](https://supabase.com)**
2. **Melde dich an oder erstelle ein Konto**
3. **Klicke auf "New Project"**
4. **Wähle deine Organisation**
5. **Fülle die Projekt-Details aus:**
   - **Name**: `grocery-app-backend`
   - **Database Password**: Sicheres Passwort generieren
   - **Region**: Wähle die nächstgelegene Region (z.B. `West Europe`)

### 2. Projekt verknüpfen

```bash
# Projekt mit Cloud verknüpfen
npx supabase link --project-ref your-project-ref

# Projekt-Ref finden:
# Supabase Dashboard -> Settings -> General -> Reference ID
```

### 3. Environment Variables für Frontend

```bash
# Im Frontend-Projekt .env.production erstellen
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 4. Keys finden

**Im Supabase Dashboard:**
1. **Settings** → **API**
2. **Project URL**: `https://your-project-ref.supabase.co`
3. **anon public**: Dein Anon Key
4. **service_role secret**: Dein Service Role Key (nur für Admin-Tasks)

## 📊 Datenbank-Deployment

### 1. Schema zu Cloud pushen

```bash
# Lokales Schema zu Cloud pushen
npx supabase db push

# Oder alle Migrationen neu ausführen
npx supabase db reset --linked
```

### 2. Seed-Daten deployen

```bash
# Seed-Daten zu Cloud pushen
npx supabase db seed --linked
```

### 3. Datenbank-Status prüfen

```bash
# Migration-Status
npx supabase migration list --linked

# Schema-Diff
npx supabase db diff --linked
```

## 🔧 Frontend-Deployment

### Option 1: Vercel (Empfohlen)

#### 1. Vercel Setup
```bash
# Im Frontend-Projekt
cd ../frontend

# Vercel CLI installieren
npm install -g vercel

# Projekt deployen
vercel

# Environment Variables in Vercel Dashboard setzen
```

#### 2. Vercel Configuration
**`vercel.json`:**
```json
{
  "version": 2,
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/static-build"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ],
  "env": {
    "NODE_ENV": "production"
  }
}
```

### Option 2: Netlify

#### 1. Netlify Setup
```bash
# Im Frontend-Projekt
cd ../frontend

# Netlify CLI installieren
npm install -g netlify-cli

# Projekt deployen
netlify deploy --prod
```

#### 2. Environment Variables
```bash
# In Netlify Dashboard oder CLI
netlify env:set SUPABASE_URL https://your-project-ref.supabase.co
netlify env:set SUPABASE_ANON_KEY your-anon-key
```

### Option 3: GitHub Pages

#### 1. GitHub Pages Setup
```bash
# Im Frontend-Projekt
cd ../frontend

# Build erstellen
npm run build

# Zu GitHub Pages deployen
# GitHub Repository -> Settings -> Pages
```

#### 2. Environment Variables
```bash
# GitHub Secrets setzen
# Repository -> Settings -> Secrets and variables -> Actions
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## 🔄 CI/CD Pipeline

### GitHub Actions

#### 1. Workflow erstellen
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm test
    
    - name: Deploy to Vercel
      uses: amondnet/vercel-action@v25
      with:
        vercel-token: ${{ secrets.VERCEL_TOKEN }}
        vercel-org-id: ${{ secrets.ORG_ID }}
        vercel-project-id: ${{ secrets.PROJECT_ID }}
        vercel-args: '--prod'
```

#### 2. Secrets setzen
**GitHub Repository** → **Settings** → **Secrets and variables** → **Actions**:
- `VERCEL_TOKEN`
- `ORG_ID`
- `PROJECT_ID`

## 🔐 Sicherheit

### 1. Environment Variables

```bash
# Nie in Git committen!
# .env.production sollte in .gitignore stehen

# Sichere Variablen:
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_URL=https://your-project-ref.supabase.co
```

### 2. CORS Configuration

```javascript
// In Supabase Dashboard -> Settings -> API
// Site URL: https://yourdomain.com
// Additional Redirect URLs: https://yourdomain.com/auth/callback
```

### 3. Row Level Security (RLS)

```sql
-- RLS ist bereits in deinem Schema aktiviert
-- Überprüfe Policies in Supabase Studio
SELECT * FROM pg_policies WHERE schemaname = 'public';
```

## 📊 Monitoring

### 1. Supabase Monitoring

```bash
# Supabase Dashboard -> Logs
# Real-time Logs anzeigen

# Performance Monitoring
# Supabase Dashboard -> Database -> Performance
```

### 2. Frontend Monitoring

```javascript
// Sentry für Frontend
import * as Sentry from "@sentry/react";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
});
```

## 🔄 Daten-Migration

### 1. Lokale Daten zu Cloud

```bash
# Lokale Daten exportieren
npx supabase db dump --file local-data.sql

# Daten zu Cloud importieren
psql "postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres" < local-data.sql
```

### 2. Benutzer-Migration

```sql
-- Benutzer von lokal zu Cloud migrieren
-- (Vorsicht: Passwörter müssen neu gesetzt werden)

INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at, 
  created_at, updated_at, confirmation_token
)
SELECT 
  id, email, encrypted_password, email_confirmed_at,
  created_at, updated_at, confirmation_token
FROM local_auth_users;
```

## 🚨 Troubleshooting

### Häufige Probleme

#### 1. CORS-Fehler
```javascript
// Supabase Dashboard -> Settings -> API
// Site URL und Redirect URLs prüfen
```

#### 2. Database Connection Issues
```bash
# Verbindung testen
npx supabase db connect --linked

# Logs prüfen
npx supabase logs --linked
```

#### 3. Environment Variables nicht gesetzt
```bash
# Variablen prüfen
echo $SUPABASE_URL
echo $SUPABASE_ANON_KEY

# In Deployment-Platform prüfen
# Vercel: vercel env ls
# Netlify: netlify env:list
```

## 📈 Performance-Optimierung

### 1. Database Indexes

```sql
-- Wichtige Indexes für Production
CREATE INDEX CONCURRENTLY idx_shopping_items_list_id_completed 
ON shopping_items(list_id, is_completed) 
WHERE is_deleted = FALSE;

CREATE INDEX CONCURRENTLY idx_lists_created_by_deleted 
ON lists(created_by, is_deleted) 
WHERE is_deleted = FALSE;
```

### 2. Frontend Optimization

```javascript
// Supabase Client optimieren
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(url, anonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
})
```

### 3. Caching

```javascript
// React Query für Caching
import { useQuery } from '@tanstack/react-query'

const { data } = useQuery({
  queryKey: ['lists'],
  queryFn: () => supabase.from('lists').select('*'),
  staleTime: 5 * 60 * 1000, // 5 Minuten
})
```

## 🔗 Nützliche Links

- [Supabase Deployment Guide](https://supabase.com/docs/guides/deployment)
- [Vercel Documentation](https://vercel.com/docs)
- [Netlify Documentation](https://docs.netlify.com/)
- [GitHub Pages](https://pages.github.com/)
- [GitHub Actions](https://docs.github.com/en/actions) 