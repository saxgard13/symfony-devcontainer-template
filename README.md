# Symfony DevContainer Template

A ready-to-use development environment for Symfony using DevContainers.

> **Note:** This template is for **local development and testing only**. Production-like configurations are included for testing purposes, not for actual deployment.

## Features

- PHP 8.3 with Xdebug, OPcache, and essential extensions
- Symfony CLI and Composer
- MySQL/MariaDB/PostgreSQL (switchable)
- Redis for caching and sessions
- Node.js for frontend tooling
- Mailpit for email testing
- Adminer for database management
- Pre-configured VS Code extensions and settings

## Requirements

- [Docker](https://www.docker.com/)
- [VS Code](https://code.visualstudio.com/) with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Git](https://git-scm.com/)

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

4. **Create project folders**:

   ```bash
   mkdir backend frontend
   ```

5. **Install Symfony**:

   ```bash
   symfony new backend --version="7.2.*" --webapp
   rm -rf backend/.git
   ```

6. **Install frontend** (optional):

   ```bash
   # Vite (recommended)
   npm create vite@latest frontend

   # Next.js
   npx create-next-app frontend

   # Then remove nested git folder
   rm -rf frontend/.git
   ```

7. **Open in container**: Press `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"

8. **Start development**:

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

## Frontend Dev Commands

When running inside Docker, use `--host` or `0.0.0.0` to make the server accessible from your browser:

| Framework   | Docker-compatible command       |
| ----------- | ------------------------------- |
| **Vite**    | `npm run dev -- --host`         |
| **Next.js** | `npm run dev -- -H 0.0.0.0`     |
| **Nuxt**    | `npm run dev -- -H 0.0.0.0`     |
| **Astro**   | `npm run dev -- --host`         |
| **CRA** *(deprecated)* | `HOST=0.0.0.0 npm start` |

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

## Multi-Root Workspaces

Use the workspace files for isolated tooling:

- `backend.code-workspace` → PHP/Symfony development
- `frontend.code-workspace` → JavaScript/React development

## Possible Improvements

- GitHub Actions CI/CD pipeline
- Makefile for common commands
- RabbitMQ integration
- Custom project scaffolding options

---

Created by saxgard13
