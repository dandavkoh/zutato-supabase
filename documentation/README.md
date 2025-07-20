# Grocery App Backend - Dokumentation

Willkommen zur Dokumentation des Grocery App Backends mit Supabase!

## 📚 Dokumentationsübersicht

### 🚀 [Getting Started](./getting-started.md)
- Systemvoraussetzungen
- Installation und Setup
- Erste Schritte

### 🛠️ [Development Guide](./development.md)
- Lokale Entwicklungsumgebung
- Supabase CLI Befehle
- Datenbank-Migrationen
- Debugging

### 🗄️ [Database Guide](./database.md)
- Datenbankschema
- Row Level Security (RLS)
- Migrationen und Seeds
- Backup und Restore

### 🌐 [Deployment Guide](./deployment.md)
- Lokale zu Produktiv-Umgebung
- Supabase Cloud Setup
- Environment Variables
- Frontend-Integration

### 🔧 [API Documentation](./api.md)
- Supabase Client API
- Authentication
- Row Level Security
- Beispiele

### 🚨 [Troubleshooting](./troubleshooting.md)
- Häufige Probleme
- Lösungen
- Debug-Tipps

## 🎯 Quick Start

```bash
# 1. Dependencies installieren
npm install

# 2. Supabase starten
npx supabase start

# 3. Datenbank zurücksetzen (erste Migration)
npx supabase db reset

# 4. Frontend mit Supabase Client verbinden
# Siehe API Documentation für Beispiele
```

## 📊 Wichtige URLs

- **Supabase Studio**: http://127.0.0.1:54323
- **API URL**: http://127.0.0.1:54321
- **GraphQL URL**: http://127.0.0.1:54321/graphql/v1

## 🔑 Wichtige Keys

```bash
# Keys anzeigen
npx supabase status
```

## 📝 Projektstruktur

```
backend/
├── documentation/          # Diese Dokumentation
├── supabase/
│   ├── config.toml        # Supabase Konfiguration
│   └── migrations/        # Datenbank-Migrationen
├── package.json           # Supabase CLI Dependency
└── .gitignore            # Git Ignore
```

## 🏗️ Architektur

Dieses Projekt verwendet **nur Supabase** ohne Custom Backend:

- ✅ **Datenbank**: PostgreSQL in Supabase
- ✅ **Authentication**: Supabase Auth
- ✅ **API**: Supabase REST/GraphQL API
- ✅ **Storage**: Supabase Storage (falls benötigt)
- ✅ **Edge Functions**: Supabase Functions (falls benötigt)

**Frontend** kommuniziert direkt mit Supabase über den Supabase Client.

## 🔄 Aktuelle Änderungen

**Dokumentation aktualisiert (Dezember 2024):**
- ✅ Entfernung aller Referenzen zu Custom Backend Server
- ✅ Fokus auf Supabase-only Architektur
- ✅ Frontend-Integration mit Supabase Client
- ✅ Korrekte Deployment-Anweisungen für Supabase Cloud
- ✅ Aktualisierte API-Dokumentation mit Supabase Client Beispielen

## 🆘 Support

Bei Problemen:
1. Schaue in die [Troubleshooting](./troubleshooting.md) Dokumentation
2. Überprüfe die [Supabase Docs](https://supabase.com/docs)
3. Erstelle ein Issue im Repository

## 🔄 Updates

Diese Dokumentation wird regelmäßig aktualisiert. Für die neueste Version siehe das Git Repository. 