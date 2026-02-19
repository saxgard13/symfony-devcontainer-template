# Production Build

This document explains the production-like configuration for testing before deployment.

> **Important:** This configuration is for **local testing in a production-like environment**, not for actual deployment. Use it to validate your application before deploying to real infrastructure.

---

## Scope & Limitations

This template supports **Symfony backend + flexible frontend (SPA/SSR/ISR)** in a **monorepo structure**:

**✅ Supported:**
- **Backend:** Symfony API (Apache)
- **Frontend:** React/Vue SPA (Vite), Next.js/Nuxt SSR, or ISR
- **Structure:** Monorepo with `/backend` and `/frontend` folders
- **Database:** MySQL (PostgreSQL/SQLite: manual config)
- **Testing:** Local production-like environment with Docker Compose

**❌ Not Supported:**
- Multi-repo (separate backend/frontend repositories)
- Alternative backends (Laravel, Django, etc.)
- Alternative web servers (Nginx instead of Apache)
- Real production deployment (K8s, managed hosting, VPS)
- Single-database setups with monorepo structure

> **Need something different?** You can use this template as a foundation and adapt the Dockerfiles, compose files, or structure to your needs. See [architecture.md](architecture.md) for implementation details.

---

## Quick Start: Testing Production Locally

**1. Stop the DevContainer** (to free up ports)
> In VS Code: *Close Remote Connection*

**2. Choose your command based on your project type:**

**Symfony API + SPA** (React, Vue — client-side rendering)
```bash
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.prod.yml \
  -f .devcontainer/docker-compose.frontend.prod.yml \
  -f .devcontainer/docker-compose.mailpit.yml \
  up -d --build
# Frontend: http://localhost:5173 — API: http://localhost:8000
```

**Symfony API + SSR** (Next.js, Nuxt — server-side rendering)
```bash
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.prod.yml \
  -f .devcontainer/docker-compose.node.prod.yml \
  -f .devcontainer/docker-compose.mailpit.yml \
  up -d --build
# Frontend: http://localhost:3000 — API: http://localhost:8000
```

**Full JavaScript SSR** (Next.js, Nuxt — sans backend Symfony)
```bash
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.node.prod.yml \
  -f .devcontainer/docker-compose.mailpit.yml \
  up -d --build
# Frontend: http://localhost:3000
```

> **PostgreSQL ?** Remplace `docker-compose.mysql.yml` par `docker-compose.postgre.yml`. Voir [Database Configuration](database.md).

**3. Run database migrations** (first launch only)
```bash
docker exec devcontainer-prod-1 php bin/console doctrine:migrations:migrate --no-interaction
```

**With HTTPS (optional):**
```bash
# Generate self-signed certificates first (one-time)
mkdir -p .devcontainer/certs
openssl req -x509 -newkey rsa:4096 -keyout .devcontainer/certs/key.pem \
  -out .devcontainer/certs/cert.pem -days 365 -nodes

# Launch with HTTPS reverse proxy
# Note: https.prod.yml is a reverse proxy layer that sits in front
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.prod.yml \              # Backend (Apache)
  -f .devcontainer/docker-compose.frontend.prod.yml \    # Frontend (Nginx SPA)
  -f .devcontainer/docker-compose.mailpit.yml \          # Email testing (optional)
  -f .devcontainer/docker-compose.https.prod.yml \       # Reverse proxy (SSL)
  up -d

# Access with HTTPS: https://localhost/
```

See [Security: HTTPS Configuration](security.md#https-in-production-with-nginx-reverse-proxy) for details.

**Stop production tests:**
```bash
docker compose down  # Stops all containers
```

---

## Choose Your Setup

| Your Setup | Compose Files | Ports |
|------------|---------------|-------|
| **Full Symfony** (no frontend) | `mysql.yml` + `prod.yml` | 8000 |
| **Symfony API + SPA** | `mysql.yml` + `prod.yml` + `frontend.prod.yml` | 8000, 5173 |
| **Symfony API + SSR** | `mysql.yml` + `prod.yml` + `node.prod.yml` | 8000, 3000 |
| **Full JavaScript (SSR)** | `mysql.yml` + `node.prod.yml` | 3000 |
| **+ HTTPS** | Add `https.prod.yml` to any above | 80, 443 |

> Les compose files de prod sont **modulaires** : ils n'incluent pas la base de données. Combine toujours avec `mysql.yml` ou `postgre.yml`. Pour SPA vs SSR, voir [Rendering Strategies](frontend-backend.md#rendering-strategies-spa-vs-ssr-vs-isr).

---

## Symfony Projects (Apache + PHP)

The production image at `.devcontainer/Dockerfile.apache.prod` handles multiple scenarios automatically.

### Automatic Asset Detection

The Dockerfile detects your project structure and builds accordingly:

| Structure | Detection | What happens |
|-----------|-----------|--------------|
| **Full Symfony** (no Node.js) | No `package.json` | PHP only, no asset build |
| **Symfony + Encore** | `backend/package.json` exists | Builds Webpack Encore assets |

> **Note:** For Symfony API + SPA, use this Dockerfile for the API only. Deploy the frontend separately (see below).

### Build and Run

```bash
# Build only (auto-detects project structure)
docker build -f .devcontainer/Dockerfile.apache.prod -t my-app:prod .
```

> Pour lancer avec `docker compose`, voir le [Quick Start](#quick-start-testing-production-locally).

### Build Stages

```dockerfile
# Stage 1: Composer dependencies
FROM php:8.3-cli AS composer-builder
# Install PHP dependencies (cached if composer.* unchanged)

# Stage 2: Node.js assets (optional)
FROM node:22-alpine AS assets-builder
# Builds frontend if package.json exists

# Stage 3: Runtime
FROM php:8.3-apache
# Copy only production files, configure Apache
```

---

## Symfony API + SPA

For Symfony backend with a separate React/Vue frontend.

### Deployment Options

The API and frontend are deployed **separately**:

| Component | Dockerfile | Compose File | Port |
|-----------|------------|--------------|------|
| **API (Symfony)** | `Dockerfile.apache.prod` | `docker-compose.prod.yml` | 8000 |
| **Frontend (SPA)** | `Dockerfile.spa.prod` | `docker-compose.frontend.prod.yml` | 5173 |

### Option 1: Both in Docker containers

> Voir la commande **Symfony API + SPA** dans le [Quick Start](#quick-start-testing-production-locally).

Accès : API `http://localhost:8000` — Frontend `http://localhost:5173` — Mailpit `http://localhost:8025`

### CORS Configuration

Since dev and prod test use the same ports, no CORS change is needed. The same configuration works for both:

```bash
CORS_ALLOW_ORIGIN=http://localhost:5173
```

### Option 2: Frontend on CDN (recommended for production)

Deploy the SPA to a static hosting service:

```bash
# Build frontend locally or in CI
cd frontend
npm run build

# Deploy to Vercel/Netlify/Cloudflare Pages
# (use their CLI or Git integration)
```

The API runs in Docker:
```bash
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.prod.yml \
  -f .devcontainer/docker-compose.mailpit.yml \
  up -d
```

### Option 3: Reverse proxy (advanced)

Use a reverse proxy (nginx, Traefik) to route requests to both containers on a single domain:

```yaml
# Example docker-compose with nginx reverse proxy
services:
  api:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile.apache.prod
    # No exposed port, accessed via nginx

  frontend:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile.spa.prod
    # No exposed port, accessed via nginx

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - api
      - frontend
```

---

## Full JavaScript (Next.js, Nuxt, Vite, etc.)

For full JavaScript applications with server-side rendering.

### Dockerfile

The production image is at `.devcontainer/Dockerfile.node.prod`.

**Features:**
- Multi-stage build (deps → builder → runner)
- Supports npm, yarn, and pnpm
- Non-root user (`appuser`)
- **Framework-agnostic template** (auto-detects build output)

### Build and Run

```bash
# Build only
docker build -f .devcontainer/Dockerfile.node.prod -t my-app:prod .
```

> Pour lancer avec `docker compose`, voir le [Quick Start](#quick-start-testing-production-locally).

### Framework Adaptation

The Dockerfile template supports multiple JavaScript frameworks. **Adapt the COPY statements in the runner stage** based on your framework's build output:

| Framework | Build Output | Adaptation |
|-----------|--------------|-----------|
| **Next.js (standalone)** | `.next/standalone`, `.next/static` | ✅ Default (uncommented) |
| **Nuxt** | `.output/` | Uncomment Nuxt CMD, modify COPY |
| **Vite (SSR)** | `dist/`, `build/` | Modify COPY paths |
| **Other frameworks** | Custom output | Adjust to match your output |

#### Next.js Configuration

For Next.js standalone output, add to `next.config.js`:

```javascript
module.exports = {
  output: 'standalone',
}
```

The Dockerfile is pre-configured for this (lines 59-62 are active).

#### Nuxt Adaptation

For Nuxt, modify the Dockerfile runner stage (lines 59-62 and 71-75):

```dockerfile
# Comment out Next.js lines, uncomment Nuxt:

# Copy Nuxt output
COPY --from=builder --chown=appuser:nodejs /app/.output ./

# Start Nuxt
CMD ["node", ".output/server/index.mjs"]
```

#### Vite/SPA with Backend

If using Vite for frontend **with a backend API**:
- Build frontend: `npm run build` → creates `dist/`
- Use `Dockerfile.spa.prod` instead (optimized for static serving)
- Deploy backend separately with `Dockerfile.apache.prod` or `Dockerfile.node.prod`

See [Symfony API + SPA section](#symfony-api--spa) for details.

---

## Environment Variables

### Symfony Production

| Variable | Value | Purpose |
|----------|-------|---------|
| `APP_ENV` | `prod` | Symfony production mode |
| `APP_DEBUG` | `0` | Disable debug output |
| `DATABASE_URL` | Connection string | Production database |

### Node.js Production

| Variable | Value | Purpose |
|----------|-------|---------|
| `NODE_ENV` | `production` | Node production mode |
| `DATABASE_URL` | Connection string | Production database |
| `PORT` | `3000` | Server port |

---

## PHP Production Settings

The production PHP config (`.devcontainer/config/php.ini.prod`) includes:

| Setting | Value | Purpose |
|---------|-------|---------|
| `display_errors` | `Off` | Never show errors to users |
| `expose_php` | `Off` | Hide PHP version |
| `opcache.validate_timestamps` | `0` | No file checks (faster) |
| `opcache.memory_consumption` | `256` | More cache memory |

---

## Layer Caching Optimization

### Symfony (Composer)

```dockerfile
# 1. Copy dependency files (cached if unchanged)
COPY backend/composer.json backend/composer.lock* ./backend/

# 2. Install dependencies (cached if composer.* unchanged)
RUN cd backend && composer install --no-dev --optimize-autoloader

# 3. Copy source code (rebuilt on every code change)
COPY . .
```

### Node.js (npm/yarn/pnpm)

```dockerfile
# 1. Copy package files
COPY frontend/package.json frontend/package-lock.json* ./

# 2. Install dependencies (cached if package*.json unchanged)
RUN npm ci

# 3. Copy source and build
COPY frontend/ .
RUN npm run build
```

---

## Database in Production

The production database has **no exposed ports** for security:

```yaml
db:
  image: mysql:8.3
  # No "ports:" section
  # Only accessible via SSH tunnel or within Docker network
```

See [Database Configuration](database.md#production-database-access) for SSH tunnel setup.

---

## Initialiser les données en production

Les fixtures Symfony (`doctrine:fixtures:load`) sont des dépendances dev et **ne sont pas disponibles** dans l'image de production. Voici les alternatives pour insérer des données initiales.

### Option 1 — Via l'API (recommandé)

> **Note sécurité :** Cette approche fonctionne uniquement si vos endpoints API ne sont pas protégés par une authentification. En production réelle, pensez à sécuriser vos routes (JWT, API key, etc.).

Si votre entité expose un endpoint `POST` via API Platform :

```bash
curl -X POST http://localhost:8000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'
```

### Option 2 — Via Adminer

Ouvrez http://localhost:8080 et connectez-vous :

| Champ | Valeur |
|-------|--------|
| Serveur | `db` |
| Utilisateur | `symfony` (valeur `MYSQL_USER` dans `.env`) |
| Mot de passe | `symfony` (valeur `MYSQL_PASSWORD` dans `.env`) |
| Base de données | `monprojet_db` (valeur `PROJECT_NAME` + `_db`) |

Puis insérez via l'onglet **SQL** :

```sql
INSERT INTO user (name, email) VALUES ('John Doe', 'john@example.com');
```

### Option 3 — Via SQL direct dans le conteneur MySQL

```bash
docker exec -it devcontainer-db-1 mysql \
  -u symfony -psymfony monprojet_db \
  -e "INSERT INTO user (name, email) VALUES ('John Doe', 'john@example.com');"
```

---

## Production Checklist

Before deploying to real production:

- [ ] Change all default passwords
- [ ] Configure real SSL certificates
- [ ] Set up proper logging and monitoring
- [ ] Configure load balancing if needed
- [ ] Set up database backups
- [ ] Review and adjust `Content-Security-Policy`
- [ ] Enable HSTS for HTTPS
- [ ] Set up health checks
- [ ] Configure rate limiting
- [ ] Review file upload limits

---

## Deployment Notes

This template provides a foundation, but real production requires additional considerations:

- **Orchestration**: Consider Kubernetes, Docker Swarm, or managed services
- **CI/CD**: Set up automated builds and deployments
- **Secrets Management**: Use Docker secrets or external vaults
- **Networking**: Configure proper DNS, reverse proxies, load balancers
- **Monitoring**: Set up APM, log aggregation, alerting
- **Scaling**: Plan for horizontal scaling if needed

---

## Évaluation pour une vraie production

Ce template est une **bonne base** (~80%) mais nécessite quelques ajustements avant un déploiement réel.

| Sujet | Statut | Problème | Solution |
|-------|--------|----------|----------|
| **Multi-stage builds** | ✅ | Images légères et optimisées | — |
| **`--no-dev` Composer** | ✅ | Dépendances de prod uniquement | — |
| **`standalone` Next.js** | ✅ | Image Node.js légère | — |
| **`restart: unless-stopped`** | ✅ | Redémarrage automatique | — |
| **Healthchecks MySQL** | ✅ | Démarrage ordonné des services | — |
| **OPcache PHP** | ✅ | Performances PHP optimisées | — |
| **Headers sécurité Apache** | ✅ | X-Frame-Options, CSP, etc. | — |
| **HTTPS/SSL** | ⚠️ | Pas de SSL par défaut | Activer `docker-compose.https.prod.yml` + Let's Encrypt |
| **Secrets** | ⚠️ | Mots de passe dans `.env` | Ne jamais committer `.env`, injecter via CI/CD |
| **APP_SECRET Symfony** | ⚠️ | Non défini | Générer et injecter une vraie valeur |
| **Port MySQL exposé** | ⚠️ | 3306 accessible sur l'hôte | Supprimer la section `ports` en prod |
| **CORS** | ⚠️ | Pointe sur `localhost` | Mettre le vrai domaine du frontend |
| **Logs** | ⚠️ | Pas d'agrégation | Ajouter Loki/Grafana ou logging cloud |
| **Backups BDD** | ⚠️ | Aucune stratégie | Cron de dump MySQL |
| **Limites ressources** | ⚠️ | Pas de limits CPU/RAM | Ajouter `deploy.resources` dans les compose files |
