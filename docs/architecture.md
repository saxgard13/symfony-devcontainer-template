# Architecture

This document describes the structure and components of the Symfony DevContainer template.

## Directory Structure

```
.
├── .devcontainer/
│   ├── config/
│   │   ├── apache/
│   │   │   └── vhost.conf           # Apache virtual host configuration
│   │   ├── php.ini                  # PHP development configuration
│   │   └── php.ini.prod             # PHP production configuration
│   ├── devcontainer.json            # VS Code DevContainer configuration
│   ├── docker-compose.dev.yml       # Development services orchestration
│   ├── docker-compose.prod.yml      # Production environment simulation
│   ├── docker-compose.mysql.yml     # MySQL database service
│   ├── docker-compose.postgre.yml   # PostgreSQL database service (alternative)
│   ├── docker-compose.redis.yml     # Redis cache service
│   ├── Dockerfile.dev               # Development container image
│   ├── Dockerfile.apache.prod       # Production Apache/PHP image
│   ├── init.sh                      # Pre-initialization script
│   ├── setup.sh                     # Post-creation setup script
│   ├── .env                         # Default environment variables
│   └── .env.local.example           # Template for local overrides
├── backend/                         # Your Symfony project (create it)
├── frontend/                        # Your frontend project (optional)
├── docs/                            # Documentation
├── backend.code-workspace           # VS Code multi-root workspace (backend)
├── frontend.code-workspace          # VS Code multi-root workspace (frontend)
├── .dockerignore                    # Files excluded from Docker builds
└── README.md                        # Quick start guide
```

## Docker Services

### Development Environment (`docker-compose.dev.yml`)

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| **dev** | `Dockerfile.dev` | 8000, 5173, 9003 | Main development container (PHP + Node.js) |
| **adminer** | `adminer:latest` | 8080 | Database administration GUI |
| **mailpit** | `axllent/mailpit` | 8025 (HTTP), 1025 (SMTP) | Email capture for testing |

### Database Services

| File | Service | Default Image | Port |
|------|---------|---------------|------|
| `docker-compose.mysql.yml` | db | `mysql:8.3` | 3306 (internal) |
| `docker-compose.postgre.yml` | db | `postgres:16` | 5432 (internal) |
| `docker-compose.redis.yml` | redis | `redis:7-alpine` | 6379 |

### Production Environment (`docker-compose.prod.yml`)

| Service | Port | Purpose |
|---------|------|---------|
| **prod** | 8081 | Apache + PHP production container |
| **db** | - | MySQL (no exposed port for security) |
| **mailpit** | 8026, 1026 | Email capture |

## Container Startup Flow

```
1. VS Code detects .devcontainer/devcontainer.json
          │
          ▼
2. Runs init.sh on host
   ├── Creates ~/.symfony5 folder (certificates)
   └── Creates Docker network "devcontainer-network"
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

All services communicate through a shared Docker network named `devcontainer-network`.

```
┌─────────────────────────────────────────────────────────────┐
│                    devcontainer-network                      │
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
