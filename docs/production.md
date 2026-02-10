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

To test your application in a production-like environment:

```bash
# 1. Stop the DevContainer (free up ports)
# (in VS Code: Close Remote Connection)

# 2. Choose your setup based on your project type (see below)

# Example: Symfony API + React SPA (with email testing)
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.prod.yml \
  -f .devcontainer/docker-compose.frontend.prod.yml \
  -f .devcontainer/docker-compose.mailpit.yml \
  up -d

# 3. Access in browser
# - Frontend: http://localhost:5173
# - API: http://localhost:8000
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

Use this table to pick the right docker-compose files for your project:

| Your Setup | Compose Files | Ports | Notes |
|------------|---------------|-------|-------|
| **Full Symfony** (no frontend) | `mysql.yml` + `docker-compose.prod.yml` | 8000 | Backend only |
| **Symfony API + React/Vue SPA** | `mysql.yml` + `prod.yml` + `frontend.prod.yml` | 8000, 5173 | Separate backend + frontend |
| **Symfony API + SPA + HTTPS** | Add `https.prod.yml` to above | 80, 443 | Nginx SSL reverse proxy |
| **Next.js / Nuxt (SSR)** | `mysql.yml` + `node.prod.yml` | 3000 | Server-side rendering |
| **Next.js + HTTPS** | `mysql.yml` + `node.prod.yml` + `https.prod.yml` | 80, 443 | Node.js + SSL |

**Pattern:**
```bash
docker compose \
  -f .devcontainer/docker-compose.<database>.yml \
  -f .devcontainer/docker-compose.<app>.yml \
  [-f .devcontainer/docker-compose.mailpit.yml] \      # Optional: Email testing
  [-f .devcontainer/docker-compose.https.prod.yml] \   # Optional: HTTPS reverse proxy
  up -d
```

---

## Rendering Strategies (SPA vs SSR vs ISR)

For detailed information on choosing between **SPA** (Single Page Application), **SSR** (Server-Side Rendering), and **ISR** (Incremental Static Regeneration), see:

[Frontend-Backend Communication: Rendering Strategies](frontend-backend.md#rendering-strategies-spa-vs-ssr-vs-isr)

**Quick reference:**
- **SPA** (React, Vue, Vite): Use `docker-compose.frontend.prod.yml`
- **SSR/ISR** (Next.js, Nuxt): Use `docker-compose.node.prod.yml`

---

## Production by Project Type

| Project Type | Dockerfile | Compose File | Port |
|--------------|------------|--------------|------|
| **Full Symfony** | `Dockerfile.apache.prod` | `docker-compose.prod.yml` | 8000 |
| **Symfony API + SPA** | `Dockerfile.apache.prod` + `Dockerfile.spa.prod` | `docker-compose.prod.yml` + `docker-compose.frontend.prod.yml` | 8000, 5173 |
| **Full JavaScript (SSR)** | `Dockerfile.node.prod` | `docker-compose.node.prod.yml` | 3000 |

> **Note:** Production test uses the same ports as development. Stop the DevContainer before running production tests to avoid port conflicts.

---

## Modular Compose Files

Production compose files are **modular** - they don't include the database service. This allows you to:
- Choose between MySQL or PostgreSQL
- Avoid configuration duplication
- Mix and match services as needed

**Always combine with a database file:**

```bash
# Pattern: database file + app file
docker compose -f .devcontainer/docker-compose.<db>.yml -f .devcontainer/docker-compose.<app>.yml up -d
```

| Database | Compose File |
|----------|--------------|
| MySQL | `docker-compose.mysql.yml` |
| PostgreSQL | `docker-compose.postgre.yml` |

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
# Build (auto-detects project structure)
docker build -f .devcontainer/Dockerfile.apache.prod -t my-app:prod .

# Run with compose (combine with database file)
# With MySQL:
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.prod.yml \
  -f .devcontainer/docker-compose.mailpit.yml \
  up -d

# With PostgreSQL:
docker compose \
  -f .devcontainer/docker-compose.postgre.yml \
  -f .devcontainer/docker-compose.prod.yml \
  -f .devcontainer/docker-compose.mailpit.yml \
  up -d

# Access at http://localhost:8000
```

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

```bash
# Build and run API + Frontend + Database (with optional email testing)
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.prod.yml \
  -f .devcontainer/docker-compose.frontend.prod.yml \
  -f .devcontainer/docker-compose.mailpit.yml \
  up -d

# Access:
# - API: http://localhost:8000
# - Frontend: http://localhost:5173
# - Mailpit (email testing): http://localhost:8025
```

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
# Build
docker build -f .devcontainer/Dockerfile.node.prod -t my-app:prod .

# Run with compose (combine with database file)
# With MySQL:
docker compose -f .devcontainer/docker-compose.mysql.yml -f .devcontainer/docker-compose.node.prod.yml up -d

# With PostgreSQL:
docker compose -f .devcontainer/docker-compose.postgre.yml -f .devcontainer/docker-compose.node.prod.yml up -d

# Access at http://localhost:3000
```

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
COPY app/package.json app/package-lock.json* ./

# 2. Install dependencies (cached if package*.json unchanged)
RUN npm ci

# 3. Copy source and build
COPY app/ .
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
