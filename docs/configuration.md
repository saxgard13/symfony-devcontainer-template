# Configuration

This document explains all configurable options in the DevContainer template.

## Environment Variables

Configuration is managed through `.devcontainer/.env` (default values) and `.devcontainer/.env.local` (your overrides).

### Project Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `PROJECT_NAME` | `monprojet` | Used for database name (`{PROJECT_NAME}_db`) and image tags |
| `PHP_VERSION` | `8.3` | PHP version for development container |
| `NODE_VERSION` | `22` | Node.js version |
| `DEV_IMAGE` | `symfony-devcontainer-template-image:php8.3-node22` | Development image name |

### Port Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `FRONTEND_LOCALHOST_PORT` | `5173` | Frontend dev server port (used for CORS in production config). Use `3000` for Next.js. |

**Port Forwarding (DevContainer):**

The following ports are automatically forwarded to your host machine via `devcontainer.json` `forwardPorts`:

| Port | Service | Notes |
|------|---------|-------|
| `8000` | Symfony backend | Exposed in docker-compose services |
| `9003` | Xdebug debugger | For VS Code debugging |
| `5173` | Frontend dev server | Vite/React/Vue |
| `3000` | Alternative frontend | Next.js compatibility |

Other services (Adminer, Mailpit) are defined in `docker-compose.*.yml` files and don't require `.env` configuration.

### Database Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_IMAGE` | `mysql:8.3` | Database Docker image |
| `SERVER_VERSION` | `8.3` | Database version (for Doctrine) |
| `MYSQL_ROOT_PASSWORD` | `roots` | MySQL root password |
| `MYSQL_USER` | `symfony` | Application database user |
| `MYSQL_PASSWORD` | `symfony` | Application database password |

**Database image examples:**
- MySQL: `mysql:8.3`
- MariaDB: `mariadb:10.11`
- PostgreSQL: `postgres:16`

### Cache & Tools Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_IMAGE` | `redis:7-alpine` | Redis Docker image |
| `ADMINER_IMAGE` | `adminer:latest` | Adminer database GUI image |

### Git Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GIT_USER_NAME` | `DefaultName` | Git commit author name |
| `GIT_USER_EMAIL` | `default@example.com` | Git commit author email |

### Other Options

| Variable | Default | Description |
|----------|---------|-------------|
| `CLEAN_VSCODE_EXTENSIONS` | `false` | Clear VS Code extensions cache on startup |

## Managing Versions (PHP, Node.js, Database, Redis, Adminer)

To simplify version management, use the centralized `.versions.json` file instead of modifying multiple files.

### Quick Start

1. **Edit `.versions.json`** to change versions:

```json
{
  "php": "8.4",
  "node": "20",
  "db_image": "postgres:16",
  "redis_image": "redis:7-alpine",
  "adminer_image": "adminer:latest"
}
```

**Available options:**
- **PHP**: Any PHP version supported by Docker official images (e.g., `8.3`, `8.4`)
- **Node.js**: Any Node.js version (e.g., `20`, `22`)
- **Database images:**
  - MySQL: `mysql:8.3`, `mysql:8.4`
  - MariaDB: `mariadb:10.11`, `mariadb:11`
  - PostgreSQL: `postgres:16`, `postgres:17`
- **Redis images**: `redis:6-alpine`, `redis:7-alpine`, `redis:latest`
- **Adminer images**: `adminer:latest`, `adminer:4.8.1`

2. **Synchronize all configuration files:**

```bash
bash scripts/update-versions.sh
```

> **Cross-Platform:** Execute this script inside your dev container (it runs in a Linux environment). This works seamlessly on **Linux, macOS, and Windows** with no special setup needed on your host machine.

This script automatically updates:
- `.devcontainer/.env` (environment variables)
- All Dockerfiles (ARG default values)
- Production image names

3. **Rebuild the development container:**

**VS Code & compatible editors** (Cursor, VSCodium): Press `Ctrl+Shift+P` and select **"Dev Containers: Rebuild Container"**.

**Other IDEs** (JetBrains, etc.): Use your IDE's container rebuild feature from the UI.

This rebuilds the container with the new versions you specified.

### What Gets Updated

Running `scripts/update-versions.sh` synchronizes versions across:

| File | What Changes |
|------|-------------|
| `.devcontainer/.env` | `PHP_VERSION`, `NODE_VERSION`, `DB_IMAGE`, `REDIS_IMAGE`, `ADMINER_IMAGE`, `DEV_IMAGE` |
| `.devcontainer/devcontainer.json` | `intelephense.environment.phpVersion` (for VS Code PHP intellisense) |
| `Dockerfile.dev` | `ARG PHP_VERSION`, `ARG NODE_VERSION` |
| `Dockerfile.apache.prod` | `ARG PHP_VERSION`, `ARG NODE_VERSION` |
| `Dockerfile.node.prod` | `ARG NODE_VERSION` |
| `Dockerfile.spa.prod` | `ARG NODE_VERSION` |

> **Note:** The `intelephense.environment.phpVersion` setting is automatically synchronized with your PHP version, so you don't need to manually update it in devcontainer.json.

> **Important:** Always rebuild the container after changing versions. The version changes only take effect after the rebuild is complete.
>
> Rebuild with:
> - **VS Code & compatible editors**: Press `Ctrl+Shift+P` → Select **"Dev Containers: Rebuild Container"**
> - **Other IDEs**: Use your IDE's container rebuild feature

> **Note:** The CI/CD pipeline uses the Dockerfile ARG defaults (maintained by `scripts/update-versions.sh`) to build images. No manual intervention needed.

## Creating .env.local

Create `.devcontainer/.env.local` from the example:

```bash
cp .devcontainer/.env.local.example .devcontainer/.env.local
```

Example content:

```bash
# Your Git identity
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your@email.com"

# Frontend port: 5173 (Vite, default) or 3000 (Next.js)
# For other frameworks, set to match your framework's default port
# FRONTEND_LOCALHOST_PORT=3000

# Custom database credentials (optional)
MYSQL_ROOT_PASSWORD=secure_password
MYSQL_USER=myapp
MYSQL_PASSWORD=myapp_password
```

> **Note:** `.env.local` is gitignored to protect your personal settings.
> Most configuration is automatic - override only what's needed.

## PHP Configuration

### Development (`config/php.ini`)

| Setting | Value | Purpose |
|---------|-------|---------|
| `memory_limit` | 512M | Generous memory for development |
| `max_execution_time` | 300 | Long timeout for debugging |
| `display_errors` | On | Show errors in browser |
| `error_reporting` | E_ALL | Report all errors |
| `opcache.validate_timestamps` | 1 | Reload code changes |
| `xdebug.mode` | debug | Enable step debugging |
| `xdebug.client_port` | 9003 | Debug connection port |

### Production (`config/php.ini.prod`)

| Setting | Value | Purpose |
|---------|-------|---------|
| `display_errors` | Off | Never show errors to users |
| `expose_php` | Off | Hide PHP version header |
| `opcache.validate_timestamps` | 0 | No timestamp checks (faster) |
| `opcache.memory_consumption` | 256 | More cache memory |
| `opcache.max_accelerated_files` | 20000 | Cache more files |

## DevContainer Services

Edit `devcontainer.json` to enable/disable services:

```json
"dockerComposeFile": [
  "docker-compose.dev.yml",
  "docker-compose.mysql.yml",    // or docker-compose.postgre.yml
  "docker-compose.redis.yml"     // remove to disable Redis
],
```

## VS Code Settings

The DevContainer configures VS Code with these settings:

```json
{
  "php.validate.executablePath": "/usr/local/bin/php",
  "intelephense.environment.phpVersion": "8.3",
  "editor.formatOnSave": true,
  "editor.tabSize": 4,
  "[php]": {
    "editor.defaultFormatter": "bmewburn.vscode-intelephense-client"
  },
  "[javascript][javascriptreact][typescript][typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

You can override these in your workspace settings.
