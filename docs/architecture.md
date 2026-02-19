# Architecture

This document describes the structure and components of the Symfony DevContainer template.

## Directory Structure

```
.
├── .devcontainer/
│   ├── config/
│   │   ├── apache/
│   │   │   └── vhost.conf           # Apache virtual host configuration
│   │   ├── nginx/
│   │   │   └── spa.conf             # Nginx SPA configuration
│   │   ├── php.ini                  # PHP development configuration
│   │   └── php.ini.prod             # PHP production configuration
│   ├── devcontainer.json            # VS Code DevContainer configuration
│   ├── docker-compose.dev.yml       # Development services orchestration
│   ├── docker-compose.prod.yml      # Apache production environment
│   ├── docker-compose.frontend.prod.yml # SPA frontend production
│   ├── docker-compose.node.prod.yml # Node.js backend production
│   ├── docker-compose.mysql.yml     # MySQL database service
│   ├── docker-compose.postgre.yml   # PostgreSQL database service (alternative)
│   ├── docker-compose.redis.yml     # Redis cache service (optional)
│   ├── docker-compose.mailpit.yml   # Email testing service (optional)
│   ├── Dockerfile.dev               # Development container image
│   ├── Dockerfile.apache.prod       # Production Apache/PHP image
│   ├── Dockerfile.spa.prod          # Production Nginx SPA image
│   ├── Dockerfile.node.prod         # Production Node.js image
│   ├── init.sh                      # Pre-initialization script
│   ├── setup.sh                     # Post-creation setup script
│   ├── .env                         # Default environment variables
│   └── .env.local.example           # Template for local overrides
├── scripts/
│   └── update-versions.sh           # Version synchronization script
├── .github/                         # GitHub workflows and templates
├── .vscode/                         # VS Code workspace settings
├── backend/                         # Your Symfony project (create it)
├── frontend/                        # Your frontend project (optional)
├── .shared/                         # Centralized project configuration and documentation
│   ├── claude.md                    # AI context for Claude Code (MCP skills, architecture notes)
│   ├── architecture.md              # System design & backend/frontend integration
│   ├── api-spec.md                  # API endpoints & contracts
│   └── conventions.md               # Shared code standards & guidelines
├── docs/                            # Documentation
├── project.code-workspace           # Multi-root workspace (Symfony API + SPA) - Recommended
├── app.code-workspace               # VS Code workspace for full JS apps
├── backend.code-workspace           # VS Code multi-root workspace (backend only)
├── frontend.code-workspace          # VS Code multi-root workspace (frontend only)
├── .versions.json                   # Centralized version configuration
├── .dockerignore                    # Files excluded from Docker builds
└── README.md                        # Quick start guide
```

## Docker Services

### Development Environment (`docker-compose.dev.yml`)

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| **dev** | `Dockerfile.dev` | 8000, 5173, 9003 | Main development container (PHP + Node.js) |
| **adminer** | `adminer:latest` | 8080 | Database administration GUI |

### Database & Cache Services

| File | Service | Default Image | Port | Type |
|------|---------|---------------|------|------|
| `docker-compose.mysql.yml` | db | `mysql:8.3` | 3306 (internal) | Database |
| `docker-compose.postgre.yml` | db | `postgres:16` | 5432 (internal) | Database (alternative) |
| `docker-compose.redis.yml` | redis | `redis:7-alpine` | 6379 | Cache (optional) |
| `docker-compose.mailpit.yml` | mailpit | `axllent/mailpit` | 8025, 1025 | Email testing (optional) |

### Production Environments

#### Apache Backend (`docker-compose.prod.yml`)

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| **prod** | `Dockerfile.apache.prod` | 8000 | Apache + PHP production backend |
| **adminer** | `adminer:latest` | 8080 | Database administration GUI |

**Optional services for production testing:**
- `docker-compose.mailpit.yml` → Email capture (`mailpit` service on port 8025/1025)

#### SPA Frontend (`docker-compose.frontend.prod.yml`)

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| **frontend** | `Dockerfile.spa.prod` | 5173 | Nginx static SPA server |

#### Node.js Backend (`docker-compose.node.prod.yml`)

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| **app** | `Dockerfile.node.prod` | 3000 | Node.js application (Next.js — officially supported) |
| **mailpit** | `axllent/mailpit` | 8025/1025 | Email capture |

## Dockerfiles Overview

The template includes 4 specialized Dockerfiles for different deployment scenarios:

### 1. Dockerfile.dev (Development)

Multi-purpose development container used inside VS Code.

**Base:** PHP 8.3 CLI with Node.js 22

**Includes:**
- Symfony CLI and Composer
- PHP Extensions: bcmath, gd, intl, opcache, pdo_mysql, xdebug, zip
- Non-root user: `vscode` (uid 1000)
- Working directory: `/workspace`
- Xdebug pre-configured on port 9003

**Use case:** Local development with full tooling

### 2. Dockerfile.apache.prod (Apache Production Backend)

Multi-stage build for Symfony applications with optional asset compilation.

**Stages:**
1. **Composer builder** - Installs PHP dependencies (cached)
2. **Node.js builder** (optional) - Builds Webpack Encore assets if `backend/package.json` exists
3. **Apache runtime** - PHP 8.3 with Apache 2.4

**Features:**
- Automatic asset detection (no Node.js if only PHP is needed)
- Apache modules: rewrite, headers enabled
- Security headers configured
- Production PHP settings
- Port: 80 (maps to 8000 on host)

**Use case:** Symfony applications (with or without Encore frontend assets)

### 3. Dockerfile.spa.prod (Nginx SPA Frontend)

Multi-stage build for static Single Page Applications.

**Stages:**
1. **Node.js builder** - Builds frontend (supports npm/yarn/pnpm)
2. **Nginx Alpine** - Serves static files

**Features:**
- Supports multiple build output formats (dist/, build/, out/)
- Nginx with gzip compression
- Static asset caching (1 year expiry)
- SPA fallback routing (all routes → /index.html)
- Health check endpoint at `/health`
- Port: 80 (maps to 5173 on host)

**Use case:** React, Vue, Vite — any static SPA. For Astro, see [Framework Adaptation Guide](framework-adaptation.md).

### 4. Dockerfile.node.prod (Node.js Backend)

Multi-stage build for server-side rendered applications.

**Stages:**
1. **Dependencies installer** - Installs npm/yarn/pnpm dependencies
2. **Builder** - Builds application
3. **Runner** - Lean production image

**Features:**
- Template pre-configured for Next.js standalone mode
- Supports npm, yarn, and pnpm
- Non-root user: `appuser`
- Port: 3000

**Use case:** Next.js SSR (officially supported). For Nuxt, Astro SSR and others, see [Framework Adaptation Guide](framework-adaptation.md).

## Container Startup Flow

```
1. VS Code detects .devcontainer/devcontainer.json
          │
          ▼
2. Runs init.sh on host
   ├── Creates ~/.symfony5 folder (certificates)
   └── Establishes Docker network "app-network"
          │
          ▼
3. Builds/pulls container images
   ├── Dockerfile.dev (PHP + Node.js + tools)
   ├── mysql:8.3 (or PostgreSQL)
   ├── redis:7-alpine
   ├── axllent/mailpit
   └── adminer:latest
          │
          ▼
4. Starts Docker Compose
   └── Waits for database healthcheck
          │
          ▼
5. Runs setup.sh inside container
   ├── Loads .env.local
   ├── Configures Git (name/email)
   └── Displays environment summary
          │
          ▼
6. VS Code installs extensions
          │
          ▼
7. Ready for development!
```

## Network Architecture

All services communicate through a shared Docker network named `app-network`.

### Development Network

```
┌─────────────────────────────────────────────────────────────┐
│                      app-network                            │
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │   dev    │    │    db    │    │  redis   │              │
│  │ PHP+Node │◄──►│  MySQL   │◄──►│  Cache   │              │
│  └────┬─────┘    └──────────┘    └──────────┘              │
│       │                                                      │
│       │          ┌──────────┐    ┌──────────┐              │
│       └─────────►│ mailpit  │    │ adminer  │              │
│                  │  Email   │    │ DB GUI   │              │
│                  └──────────┘    └──────────┘              │
└─────────────────────────────────────────────────────────────┘
         │              │              │
    localhost:8000  localhost:8025  localhost:8080
    localhost:5173
```

### Production Network Options

#### Option 1: Symfony API + SPA

```
┌──────────────────────────────────────────────────────┐
│                   app-network                         │
│                                                       │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐  │
│  │   prod     │  │ frontend   │  │   db         │  │
│  │ Apache/PHP │  │   Nginx    │  │  MySQL       │  │
│  └──────┬─────┘  └──────┬─────┘  └──────────────┘  │
│         │              │                            │
│         └──────┬───────┘                            │
│                │      ┌──────────┐                  │
│                └─────►│ mailpit  │                  │
│                       │  Email   │                  │
│                       └──────────┘                  │
└──────────────────────────────────────────────────────┘
    localhost:8000    localhost:5173
```

#### Option 2: Node.js Backend

```
┌──────────────────────────────────────┐
│        app-network                   │
│                                      │
│  ┌──────────┐    ┌──────────────┐   │
│  │   app    │    │   db         │   │
│  │ Node.js  │◄──►│  MySQL       │   │
│  └────┬─────┘    └──────────────┘   │
│       │                              │
│       │    ┌──────────┐              │
│       └───►│ mailpit  │              │
│            │  Email   │              │
│            └──────────┘              │
└──────────────────────────────────────┘
    localhost:3000
```

## Multi-Root Workspace & Shared Configuration

### The `.shared/` Folder

The `.shared/` folder serves as the centralized hub for project-wide configuration and documentation, enabling seamless collaboration and AI-assisted development with tools like Claude Code.

**Contents:**
- **`claude.md`** - AI context file for Claude Code, including MCP skills configuration, custom instructions, and high-level architecture notes
- **`architecture.md`** - System design documenting backend/frontend integration patterns
- **`api-spec.md`** - OpenAPI/REST API endpoints and contracts
- **`conventions.md`** - Shared coding standards, naming conventions, and guidelines

**Purpose:** Ensures that backend and frontend teams follow consistent patterns while maintaining independent repositories. When using Claude Code with the `project.code-workspace`, it has immediate access to all shared context.

### Multi-Root Workspaces

VS Code Multi-Root Workspaces allow flexible project organization while maintaining a unified development environment.

**Available Workspaces:**

| Workspace File | Folders Included | Use Case |
|---|---|---|
| **`project.code-workspace`** (Recommended) | `.shared/`, `backend/`, `frontend/` | Symfony API + SPA development together |
| **`backend.code-workspace`** | `backend/` only | Backend-only development |
| **`frontend.code-workspace`** | `frontend/` only | Frontend-only or Full JavaScript (Next.js) |

**Why Use Multi-Root Workspaces:**
- ✅ Each folder has isolated VSCode settings, extensions, and terminals
- ✅ Cleaner sidebar without configuration file clutter
- ✅ PHP-CS-Fixer runs only on backend, ESLint only on frontend
- ✅ Claude Code can see both backend and frontend context when using `project.code-workspace`
- ✅ Developers can focus on one part independently if needed

**Opening a Workspace:**
1. Open the `.code-workspace` file in VS Code
2. When prompted, reopen in container
3. When prompted about Git repository in parent folders, choose **Yes**

## Configuration Files

### PHP Configuration

**Development** (`.devcontainer/config/php.ini`):
- Memory limit: 512M
- Upload size: 64MB
- Timezone: Europe/Paris
- OPcache enabled (with development settings)
- XDebug configured on port 9003
- Error display: enabled
- All errors reported

**Production** (`.devcontainer/config/php.ini.prod`):
- OPcache optimized (no timestamp validation)
- Errors hidden from users
- PHP version hidden from headers
- Extended opcache memory (256M)

### Apache Configuration

**Virtual Host** (`.devcontainer/config/apache/vhost.conf`):
- Document root: `/var/www/html/public`
- Rewrites enabled (for Symfony routing)
- Security headers configured:
  - X-Frame-Options: DENY
  - X-Content-Type-Options: nosniff
  - X-XSS-Protection: enabled
  - Content-Security-Policy configured

### Nginx Configuration

**SPA Server** (`.devcontainer/config/nginx/spa.conf`):
- Root: `/usr/share/nginx/html`
- Gzip compression enabled
- Static assets cached (1 year)
- SPA fallback: all routes → `/index.html`
- Health check endpoint: `/health`

## Version Management

### .versions.json

Centralized configuration file that defines all major component versions:

```json
{
  "php": "8.3",
  "node": "22",
  "db_image": "mysql:8.3",
  "server_version": "8.3",
  "redis_image": "redis:7-alpine",
  "adminer_image": "adminer:latest"
}
```

The `scripts/update-versions.sh` script synchronizes these versions across:
- `.devcontainer/.env` (environment variables)
- All 4 Dockerfiles (ARG defaults)
- Production image names

This ensures consistency across development and production builds.

## Setup Scripts

### init.sh (Host-side initialization)

Runs on the host machine before container starts:
- Creates `~/.symfony5` folder for HTTPS certificates
- Establishes Docker network `app-network`

### setup.sh (Container-side initialization)

Runs inside the container after startup:
- Loads `.env.local` configuration
- Configures Git identity (user.name, user.email)
- Displays environment summary
- Performs health checks

## Port Mapping Summary

| Service | Internal Port | Host Port | Purpose |
|---------|---------------|-----------|---------|
| **Symfony Backend** | 8000 | 8000 | API/Web server |
| **Frontend Dev Server** | 5173 | 5173 | Vite/SPA development |
| **Node.js App** | 3000 | 3000 | Next.js SSR |
| **XDebug** | 9003 | 9003 | Step debugging |
| **Database (MySQL)** | 3306 | - | Internal only |
| **Database (PostgreSQL)** | 5432 | - | Internal only |
| **Redis** | 6379 | - | Internal only |
| **Mailpit HTTP** | 1025 | 8025 | Email testing UI |
| **Mailpit SMTP** | 1025 | 1025 | Email capture |
| **Adminer** | 8080 | 8080 | Database management |

> **Note:** Database and Redis ports are not exposed to host for security. They're only accessible within the Docker network and the dev container.

## VS Code Extensions

The DevContainer automatically installs these extensions:

| Category | Extension | Purpose |
|----------|-----------|---------|
| **Debugging** | xdebug.php-debug | PHP step debugging |
| **PHP** | bmewburn.vscode-intelephense-client | PHP IntelliSense |
| **PHP** | MehediDracula.php-namespace-resolver | Auto-import classes |
| **PHP** | neilbrayfield.php-docblocker | PHPDoc generation |
| **PHP** | junstyle.php-cs-fixer | Code style fixing |
| **Database** | cweijan.vscode-mysql-client2 | MySQL client |
| **Database** | alexcvzz.vscode-sqlite | SQLite client |
| **Frontend** | dsznajder.es7-react-js-snippets | React snippets |
| **Frontend** | esbenp.prettier-vscode | Code formatting |
| **Frontend** | dbaeumer.vscode-eslint | JavaScript linting |
| **Templating** | mblode.twig-language-2 | Twig syntax |
| **Utilities** | joffreykern.markdown-toc | Markdown TOC |
| **Utilities** | mikestead.dotenv | .env file support |
| **Utilities** | ritwickdey.LiveServer | Live server |

## Volume Mounts

| Host | Container | Purpose |
|------|-----------|---------|
| Project folder | `/workspace` | Code editing |
| `~/.ssh` | `/home/vscode/.ssh` | Git/SSH access |
| `~/.symfony5` | `/home/vscode/.symfony5` | Symfony certificates |
| `db-data` (volume) | `/var/lib/mysql` | Database persistence |
| `redis-data` (volume) | `/data` | Redis persistence |
| `uploads` (volume) | `/var/www/html/public/uploads` | Production file uploads |
| `logs` (volume) | `/var/www/html/var/log` | Production application logs |

## Deployment Scenarios

This template supports multiple project architectures. Choose the appropriate Dockerfiles and compose files:

### Scenario 1: Symfony API + SPA Frontend

**Use when:** Backend and frontend are separate projects

**Dockerfiles:**
- Backend: `Dockerfile.apache.prod`
- Frontend: `Dockerfile.spa.prod`

**Compose files:**
```bash
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.prod.yml \
  -f .devcontainer/docker-compose.frontend.prod.yml \
  -f .devcontainer/docker-compose.mailpit.yml \      # Optional: email testing
  up -d
```

**Resulting services:**
- `prod` (Apache/PHP) on port 8000
- `frontend` (Nginx SPA) on port 5173
- `db` (MySQL, internal)
- `mailpit` (email testing, optional) on port 8025/1025

### Scenario 2: Full Symfony Application

**Use when:** Single Symfony project with templates (no separate frontend repo)

**Dockerfiles:**
- `Dockerfile.apache.prod` (auto-detects if Webpack Encore is needed)

**Compose files:**
```bash
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.prod.yml \
  -f .devcontainer/docker-compose.mailpit.yml \      # Optional: email testing
  up -d
```

**Resulting services:**
- `prod` (Apache/PHP) on port 8000
- `db` (MySQL, internal)
- `mailpit` (email testing, optional) on port 8025/1025

### Scenario 3: Node.js Backend (Next.js)

**Use when:** Full JavaScript application with server-side rendering

**Dockerfiles:**
- `Dockerfile.node.prod`

**Compose files:**
```bash
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.node.prod.yml \
  -f .devcontainer/docker-compose.mailpit.yml \      # Optional: email testing
  up -d
```

**Resulting services:**
- `app` (Node.js) on port 3000
- `db` (MySQL, internal)
- `mailpit` (email testing, optional) on port 8025/1025

### Local Development (All Scenarios)

**Single compose file for everything** (or use VS Code DevContainer):
```bash
docker compose \
  -f .devcontainer/docker-compose.dev.yml \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.redis.yml \
  -f .devcontainer/docker-compose.mailpit.yml \
  up -d
```

> **Note:** In VS Code, opening the project with **Reopen in Container** automatically loads all files configured in `devcontainer.json`.

**All available services:**
- `dev` (development container) on ports 8000, 5173, 9003
- `db` (MySQL)
- `redis` (cache)
- `mailpit` (email)
- `adminer` (database GUI) on port 8080

## Environment Variables

Configuration is managed through:

| File | Purpose | Committed to Git |
|------|---------|-----------------|
| `.devcontainer/.env` | Default values (PHP, Node versions, ports) | ✅ Yes |
| `.devcontainer/.env.local` | Local overrides (Git user, credentials) | ❌ No (gitignored) |
| `.versions.json` | Centralized version config | ✅ Yes |

The `scripts/update-versions.sh` script synchronizes `.versions.json` changes to all Dockerfiles and `.env` files.

---

## Documentation Index

For detailed information about setting up and using the template, refer to these guides:

| Document | Purpose |
|----------|---------|
| **[Usage Guide](usage.md)** | Installation, project setup, starting development servers, and basic commands |
| **[Configuration](configuration.md)** | Customizing PHP, Node.js, database versions and environment variables |
| **[Database](database.md)** | MySQL/PostgreSQL setup, migrations, SSH tunnels, and database management |
| **[Redis](redis.md)** | Caching, sessions, and Redis configuration |
| **[Security](security.md)** | Security headers, secrets management, and best practices |
| **[Xdebug](xdebug.md)** | Setting up PHP step debugging |
| **[Frontend ↔ Backend](frontend-backend.md)** | CORS, API communication, and development patterns |
| **[Quality Tools](quality-tools.md)** | PHP-CS-Fixer, PHPStan, ESLint, Prettier, and TypeScript configuration |
| **[Development Tools](development-tools.md)** | Debug Bundle, Profiler, Maker Bundle, testing frameworks (Jest/Vitest, Storybook) |
| **[Workflows](workflows.md)** | GitHub Actions CI/CD pipeline setup for quality, tests, security, and deployment |
| **[Advanced](advanced.md)** | Advanced configurations, troubleshooting, and optimization tips |
| **[Production](production.md)** | Building and testing production Docker images |
| **[Framework Adaptation](framework-adaptation.md)** | Adapting the template for Nuxt, Astro, and other frameworks |
