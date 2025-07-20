# Development Guide

## 🛠️ Lokale Entwicklungsumgebung

### Supabase Services starten/stoppen

```bash
# Supabase starten
npx supabase start

# Supabase stoppen
npx supabase stop

# Status prüfen
npx supabase status

# Services neu starten
npx supabase restart
```

### Frontend-Entwicklung

```bash
# Frontend-Projekt (separates Repository)
cd ../frontend  # oder wo dein Frontend ist

# Development Server starten
npm run dev

# Tests ausführen
npm test
```

## 🗄️ Datenbank-Migrationen

### Migration erstellen

```bash
# Neue Migration erstellen
npx supabase migration new migration_name

# Beispiel:
npx supabase migration new add_user_profile_table
```

### Migrationen ausführen

```bash
# Alle Migrationen ausführen
npx supabase db reset

# Nur neue Migrationen ausführen
npx supabase db push

# Migrationen zurücksetzen
npx supabase db reset --linked
```

### Migration Status

```bash
# Migration Status anzeigen
npx supabase migration list

# Datenbank Schema anzeigen
npx supabase db diff
```

### Seed Data

```bash
# Seed-Daten ausführen
npx supabase db reset --seed

# Nur Seed-Daten ausführen
npx supabase db seed
```

## 🔧 Supabase CLI Befehle

### Projekt-Management

```bash
# Projekt initialisieren
npx supabase init

# Projekt verknüpfen (mit Cloud-Projekt)
npx supabase link --project-ref your-project-ref

# Projekt-Status
npx supabase status

# Logs anzeigen
npx supabase logs
```

### Datenbank-Operationen

```bash
# Datenbank zurücksetzen
npx supabase db reset

# Schema-Diff erstellen
npx supabase db diff

# Schema zu Cloud pushen
npx supabase db push

# Schema von Cloud pullen
npx supabase db pull
```

### Functions

```bash
# Edge Functions erstellen
npx supabase functions new function_name

# Functions deployen
npx supabase functions deploy

# Functions lokal testen
npx supabase functions serve
```

### Storage

```bash
# Storage Buckets erstellen
npx supabase storage create bucket_name

# Storage Policies setzen
npx supabase storage policy create
```

## 🐛 Debugging

### Logs anzeigen

```bash
# Supabase Logs
npx supabase logs

# Spezifische Service Logs
npx supabase logs --service postgres
npx supabase logs --service api
npx supabase logs --service auth

# Logs in Echtzeit
npx supabase logs --follow
```

### Datenbank-Debugging

```bash
# Direkte Verbindung zur Datenbank
npx supabase db connect

# SQL Editor öffnen
# Gehe zu http://127.0.0.1:54323 -> SQL Editor
```

### API-Debugging

```bash
# API-Tests mit curl
curl -X GET http://127.0.0.1:54321/rest/v1/lists \
  -H "apikey: your-anon-key" \
  -H "Authorization: Bearer your-token"

# GraphQL-Tests
curl -X POST http://127.0.0.1:54321/graphql/v1 \
  -H "Content-Type: application/json" \
  -H "apikey: your-anon-key" \
  -d '{"query":"{ lists { id name } }"}'
```

## 🔍 Entwicklungstools

### Supabase Studio

**URL**: http://127.0.0.1:54323

**Features:**
- **Table Editor**: Tabellen und Daten anzeigen/bearbeiten
- **SQL Editor**: SQL-Abfragen ausführen
- **Authentication**: Benutzer verwalten
- **Storage**: Dateien verwalten
- **Edge Functions**: Serverless Functions
- **Logs**: System-Logs anzeigen

### Database Tools

```bash
# DBeaver (empfohlen)
# Verbindungsdaten:
# Host: 127.0.0.1
# Port: 54322
# Database: postgres
# Username: postgres
# Password: postgres

# pgAdmin
# Gleiche Verbindungsdaten wie oben
```

### API Testing

```bash
# Postman Collection erstellen
# Base URL: http://127.0.0.1:54321
# Headers:
#   apikey: your-anon-key
#   Authorization: Bearer your-token
```

## 📝 Entwicklungsworkflow

### 1. Feature Development

```bash
# 1. Neuen Branch erstellen
git checkout -b feature/new-feature

# 2. Migration erstellen
npx supabase migration new add_new_table

# 3. Migration bearbeiten
# supabase/migrations/YYYYMMDDHHMMSS_add_new_table.sql

# 4. Migration testen
npx supabase db reset

# 5. Frontend-Code schreiben und testen
# cd ../frontend && npm run dev

# 6. Committen
git add .
git commit -m "Add new feature"

# 7. Push und Pull Request
git push origin feature/new-feature
```

### 2. Database Changes

```bash
# 1. Schema ändern
# supabase/migrations/...sql bearbeiten

# 2. Lokal testen
npx supabase db reset

# 3. Diff erstellen
npx supabase db diff

# 4. Neue Migration erstellen
npx supabase migration new descriptive_name

# 5. Testen
npx supabase db reset
```

### 3. Testing

```bash
# Frontend Tests
cd ../frontend
npm test

# Integration Tests
npm run test:integration

# E2E Tests
npm run test:e2e

# Coverage
npm run test:coverage
```

## 🔄 Hot Reload

### Supabase Auto-Reload

```bash
# Migrationen werden automatisch neu geladen
# Nach Änderungen in supabase/migrations/
npx supabase db reset
```

### Frontend Auto-Reload

```bash
# Im Frontend-Projekt
npm run dev  # Auto-reload bei Code-Änderungen
```

## 📊 Monitoring

### Performance Monitoring

```bash
# Datenbank-Performance
npx supabase db connect
# Dann: EXPLAIN ANALYZE your_query;

# API-Performance
# Supabase Studio -> Logs
```

### Error Tracking

```bash
# Supabase Logs
npx supabase logs --follow

# Frontend Logs
# In der Browser-Konsole
```

## 🚀 Production Preparation

### Environment Variables

```bash
# Frontend .env.production erstellen
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=your-anon-key
# NODE_ENV=production
```

### Frontend Build Process

```bash
# Frontend Production Build
cd ../frontend
npm run build

# Start Production Server
npm start

# Mit PM2
npm install -g pm2
pm2 start npm --name "grocery-app-frontend" -- start
```

## 🎯 Best Practices

### Code Organization

```
project/
├── backend/              # Dieses Repository
│   ├── supabase/
│   │   ├── config.toml
│   │   └── migrations/
│   └── documentation/
└── frontend/             # Separates Repository
    ├── src/
    ├── public/
    └── package.json
```

### Database Best Practices

- **Migrationen**: Immer neue Migrationen für Schema-Änderungen
- **Seeds**: Nur Test-Daten, keine Produktions-Daten
- **RLS**: Immer aktiviert für Sicherheit
- **Indexes**: Für Performance bei großen Tabellen

### Frontend Best Practices

- **Supabase Client**: Konsistente Verwendung
- **Error Handling**: Supabase Errors behandeln
- **Authentication**: Session-Management
- **Type Safety**: TypeScript mit Supabase Types

## 🔗 Nützliche Links

- [Supabase CLI Docs](https://supabase.com/docs/reference/cli)
- [Supabase JavaScript Client](https://supabase.com/docs/reference/javascript)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [React/Vue/Next.js Docs](https://reactjs.org/) 