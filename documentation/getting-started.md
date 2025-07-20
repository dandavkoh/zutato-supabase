# Getting Started

## 🖥️ Systemvoraussetzungen

### Mindestanforderungen
- **Betriebssystem**: macOS 10.15+, Windows 10+, oder Linux
- **RAM**: 4GB (8GB empfohlen)
- **Speicherplatz**: 2GB freier Speicherplatz
- **Internetverbindung**: Für Download und Updates

### Erforderliche Software

#### 1. Node.js
- **Version**: 18.x oder höher
- **Download**: [nodejs.org](https://nodejs.org/)
- **Überprüfung**: `node --version` und `npm --version`

#### 2. Docker Desktop
- **Version**: 20.10+ (für Supabase lokal)
- **Download**: [docker.com](https://www.docker.com/products/docker-desktop/)
- **Überprüfung**: `docker --version`
- **Wichtig**: Docker muss laufen für Supabase lokal

#### 3. Git
- **Version**: 2.30+ (für Versionskontrolle)
- **Download**: [git-scm.com](https://git-scm.com/)
- **Überprüfung**: `git --version`

### Optionale Software
- **VS Code**: Empfohlener Editor
- **Postman**: API Testing
- **DBeaver**: Datenbank-Management

## 🚀 Installation

### 1. Repository klonen
```bash
git clone <repository-url>
cd "Grocery App/backend"
```

### 2. Dependencies installieren
```bash
npm install
```

### 3. Supabase CLI installieren (falls nicht global)
```bash
npm install -g supabase
# oder lokal verwenden: npx supabase
```

### 4. Docker starten
```bash
# Docker Desktop öffnen und warten bis es läuft
docker --version
```

## 🎯 Erste Schritte

### 1. Supabase initialisieren
```bash
# Falls noch nicht geschehen
npx supabase init
```

### 2. Supabase lokal starten
```bash
npx supabase start
```

**Erwartete Ausgabe:**
```
Started supabase local development setup.

         API URL: http://127.0.0.1:54321
     GraphQL URL: http://127.0.0.1:54321/graphql/v1
  S3 Storage URL: http://127.0.0.1:54321/storage/v1/s3
          DB URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres
      Studio URL: http://127.0.0.1:54323
    Inbucket URL: http://127.0.0.1:54324
```

### 3. Datenbank-Migrationen ausführen
```bash
npx supabase db reset
```

### 4. Überprüfung
- **Supabase Studio**: http://127.0.0.1:54323
- **API Health**: http://127.0.0.1:54321/rest/v1/

## 🔧 Konfiguration

### Environment Variables für Frontend
```bash
# .env Datei im Frontend-Projekt erstellen
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=your-anon-key
```

### Supabase Keys finden
```bash
npx supabase status
```

## 📊 Dashboard öffnen

### Supabase Studio
1. Öffne http://127.0.0.1:54323 im Browser
2. Navigiere zu **Table Editor**
3. Überprüfe die erstellten Tabellen:
   - `lists`
   - `list_members`
   - `categories`
   - `units`
   - `shopping_items`

### SQL Editor
1. Im Supabase Studio zu **SQL Editor** navigieren
2. Teste eine Abfrage:
```sql
SELECT * FROM categories;
SELECT * FROM units;
```

## 🧪 Erste Tests

### 1. API Health Check
```bash
curl http://127.0.0.1:54321/rest/v1/
```

### 2. Benutzer registrieren (über Frontend)
```javascript
// Im Frontend mit Supabase Client
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(url, anonKey)

const { data, error } = await supabase.auth.signUp({
  email: 'test@example.com',
  password: 'password123'
})
```

### 3. Benutzer anmelden (über Frontend)
```javascript
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'test@example.com',
  password: 'password123'
})
```

## 🚨 Häufige Probleme

### Docker läuft nicht
```bash
# Docker Status prüfen
docker ps

# Docker Desktop neu starten
# Dann erneut versuchen:
npx supabase start
```

### Ports bereits belegt
```bash
# Ports prüfen
lsof -i :54321
lsof -i :54322
lsof -i :54323

# Supabase stoppen und neu starten
npx supabase stop
npx supabase start
```

### Node.js Version zu alt
```bash
# Version prüfen
node --version

# Node.js aktualisieren (nvm empfohlen)
nvm install 18
nvm use 18
```

## ✅ Checkliste

- [ ] Node.js 18+ installiert
- [ ] Docker Desktop installiert und läuft
- [ ] Git installiert
- [ ] Repository geklont
- [ ] Dependencies installiert (`npm install`)
- [ ] Supabase gestartet (`npx supabase start`)
- [ ] Migrationen ausgeführt (`npx supabase db reset`)
- [ ] Supabase Studio erreichbar (http://127.0.0.1:54323)
- [ ] API erreichbar (http://127.0.0.1:54321/rest/v1/)

## 🎉 Nächste Schritte

Nach erfolgreicher Installation:
1. [Development Guide](./development.md) lesen
2. [Database Guide](./database.md) verstehen
3. [API Documentation](./api.md) studieren
4. Frontend mit Supabase Client verbinden
5. Mit der Entwicklung beginnen! 