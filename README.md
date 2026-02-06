# Symfony DevContainer Template

[![PHP Configurable](https://img.shields.io/badge/PHP-Configurable-777BB4?logo=php&logoColor=white)](docs/configuration.md)
[![Node.js Configurable](https://img.shields.io/badge/Node.js-Configurable-339933?logo=node.js&logoColor=white)](docs/configuration.md)
[![Symfony](https://img.shields.io/badge/Symfony-Ready-000000?logo=symfony&logoColor=white)](https://symfony.com/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Dev Containers](https://img.shields.io/badge/Dev%20Containers-Supported-007ACC?logo=visualstudiocode&logoColor=white)](https://code.visualstudio.com/docs/devcontainers/containers)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A ready-to-use development environment for Symfony using DevContainers.

> **Note:** This template is for **local development and testing only**. Production-like configurations are included for testing purposes, not for actual deployment.

## Features

- **PHP** (configurable, default 8.3) with Xdebug, OPcache, and essential extensions
- Symfony CLI and Composer
- MySQL/MariaDB/PostgreSQL (switchable)
- Redis for caching and sessions
- **Node.js** (configurable, default 22) for frontend tooling
- Mailpit for email testing
- Adminer for database management
- Pre-configured VS Code extensions and settings

## Requirements

- [Docker](https://www.docker.com/)
- **VS Code** with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
  - Or any **VS Code-compatible IDE** with Dev Containers support (Cursor, VSCodium, etc.)
  - Other IDEs like JetBrains (PhpStorm, IntelliJ) also support Dev Containers, but with different UI
- [Git](https://git-scm.com/)

> **Note:** This template and documentation are optimized for **VS Code and compatible editors**. Instructions use VS Code's command palette (`Ctrl+Shift+P`). If you use another IDE, adjust the rebuild process accordingly.

## Quick Start

1. **Create your repository** from this template (click "Use this template" on GitHub)

2. **Clone and open** in VS Code:

   ```bash
   git clone git@github.com:your-username/your-project.git
   code your-project
   ```

3. **Configure Git identity** (before opening in container):

   ```bash
   cp .devcontainer/.env.local.example .devcontainer/.env.local
   # Edit .env.local with your name and email
   ```

4. **⚠️ Open in container** (REQUIRED before installing Symfony/npm): Press `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"

   The following steps require Symfony CLI and Node.js, which are only available inside the container.

5. **Create project folders** (inside container):

   ```bash
   mkdir backend frontend
   ```

6. **Customize versions** (optional, inside container):

   Edit `.versions.json` to change PHP, Node.js, or database versions before proceeding. See [Configuration Guide](docs/configuration.md#managing-versions-php-nodejs-database) for available options.

7. **Install Symfony** (inside container):

   ```bash
   # With web interface (recommended for traditional apps)
   symfony new backend --version="7.2.*" --webapp

   # Or for API-only projects (without --webapp)
   symfony new backend --version="7.2.*"
   ```

   Choose the Symfony version based on your PHP version:
   - PHP 8.3: Supports Symfony 6.4+, 7.x
   - PHP 8.4: Supports Symfony 7.x

   ```bash
   rm -rf backend/.git
   ```

8. **Install frontend** (optional, choose your framework, inside container):

   ```bash
   # Popular options:
   npm create vite@latest frontend              # Vite (recommended)
   npx create-next-app frontend                 # Next.js
   npx create-react-app frontend                # Create React App
   npx create-nuxt-app frontend                 # Nuxt
   npm create astro frontend                    # Astro

   # Or any other npm-based framework
   ```

   ```bash
   # Remove nested git folder
   rm -rf frontend/.git
   ```

9. **Start development**:

   ```bash
   # Backend
   cd backend
   symfony server:start --no-tls --allow-http --listen-ip=0.0.0.0 --port=8000
   ```

   ```bash
   # Frontend (in another terminal)
   cd frontend
   npm run dev -- --host
   ```

## Customizing Versions

To use different versions of PHP, Node.js, or database:

1. **Edit `.versions.json`**:

   ```json
   {
     "php": "8.4",
     "node": "20",
     "db_image": "postgres:16"
   }
   ```

2. **Synchronize all configuration files**:

   ```bash
   bash scripts/update-versions.sh
   ```

3. **⚠️ Rebuild the development container** (REQUIRED):

   **VS Code & compatible editors** (Cursor, VSCodium): Press `Ctrl+Shift+P` and select **"Dev Containers: Rebuild Container"**.

   **Other IDEs** (JetBrains, etc.): Use your IDE's container rebuild feature from the UI.

   The version changes only take effect after rebuilding. Skipping this step means your container will still use the old versions.

This updates the development environment and Dockerfiles. The CI/CD pipeline automatically uses the updated Dockerfile ARG defaults.

> **Note:** The `update-versions.sh` script runs inside the dev container (Linux environment), so it works seamlessly on **Linux, macOS, and Windows**. No special tools needed on your host machine!

See [Configuration Guide](docs/configuration.md#managing-versions-php-nodejs-database) for all available options.

## Frontend Dev Commands

When running inside Docker, use `--host` or `0.0.0.0` (or equivalent) to make the dev server accessible from your browser. Here are examples for popular frameworks:

> **Note:** These commands are for reference. You can use any npm-based framework - adapt the command according to your framework's documentation.

| Framework              | Docker-compatible command   |
| ---------------------- | --------------------------- |
| **Vite**               | `npm run dev -- --host`     |
| **Next.js**            | `npm run dev -- -H 0.0.0.0` |
| **Nuxt**               | `npm run dev -- -H 0.0.0.0` |
| **Astro**              | `npm run dev -- --host`     |
| **CRA** _(deprecated)_ | `HOST=0.0.0.0 npm start`    |

## Services

| Service  | URL                   | Purpose             |
| -------- | --------------------- | ------------------- |
| Backend  | http://localhost:8000 | Symfony application |
| Frontend | http://localhost:5173 | Frontend dev server |
| Adminer  | http://localhost:8080 | Database GUI        |
| Mailpit  | http://localhost:8025 | Email testing       |

## Database

| Setting  | Value                                |
| -------- | ------------------------------------ |
| Host     | `db`                                 |
| Port     | `3306` (MySQL) / `5432` (PostgreSQL) |
| User     | `symfony`                            |
| Password | `symfony`                            |
| Database | `{PROJECT_NAME}_db`                  |

## Documentation

| Topic                            | Document                                       |
| -------------------------------- | ---------------------------------------------- |
| Project structure & services     | [Architecture](docs/architecture.md)           |
| Environment variables & settings | [Configuration](docs/configuration.md)         |
| MySQL, PostgreSQL, SSH tunnels   | [Database](docs/database.md)                   |
| Cache & sessions                 | [Redis](docs/redis.md)                         |
| Headers, secrets, best practices | [Security](docs/security.md)                   |
| Step debugging setup             | [Xdebug](docs/xdebug.md)                       |
| Installation & workspaces        | [Usage Guide](docs/usage.md)                   |
| CORS & API communication         | [Frontend ↔ Backend](docs/frontend-backend.md) |
| Building & testing prod images   | [Production](docs/production.md)               |

## Project Types

This template supports multiple project structures:

| Type                  | Folders                  | Workspace                |
| --------------------- | ------------------------ | ------------------------ |
| **Symfony API + SPA** | `backend/` + `frontend/` | Both workspace files     |
| **Full Symfony**      | `backend/` only          | `backend.code-workspace` |
| **Full JavaScript**   | `app/`                   | `app.code-workspace`     |

See [Usage Guide](docs/usage.md) for detailed setup instructions.

## Multi-Root Workspaces

Use the workspace files for isolated tooling:

- `backend.code-workspace` → PHP/Symfony development
- `frontend.code-workspace` → JavaScript SPA (React/Vue)
- `app.code-workspace` → Full JS apps (Next.js, Nuxt)

## Possible Improvements

- GitHub Actions CI/CD pipeline
- Makefile for common commands
- RabbitMQ integration
- Custom project scaffolding options

---

---

Created by saxgard13
