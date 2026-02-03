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
| `BACKEND_PORT` | `8000` | Symfony server port |
| `FRONTEND_LOCALHOST_PORT` | `5173` | Frontend dev server port (host) |
| `FRONTEND_INTERNAL_PORT` | `5173` | Frontend port inside Docker network |
| `ADMINER_PORT` | `8080` | Adminer database GUI port |
| `ADMINER_PORT_PROD_TEST` | `8081` | Adminer port for production testing |
| `MAILPIT_HTTP_PORT` | `8025` | Mailpit web interface port |
| `MAILPIT_SMTP_PORT` | `1025` | Mailpit SMTP port |

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

### Git Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GIT_USER_NAME` | `DefaultName` | Git commit author name |
| `GIT_USER_EMAIL` | `default@example.com` | Git commit author email |

### Other Options

| Variable | Default | Description |
|----------|---------|-------------|
| `CLEAN_VSCODE_EXTENSIONS` | `false` | Clear VS Code extensions cache on startup |

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

# Custom database credentials (optional)
MYSQL_ROOT_PASSWORD=secure_password
MYSQL_USER=myapp
MYSQL_PASSWORD=myapp_password
```

> **Note:** `.env.local` is gitignored to protect your personal settings.

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
