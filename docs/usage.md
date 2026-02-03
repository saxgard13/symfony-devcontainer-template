# Usage Guide

This guide explains how to set up and use the DevContainer template.

## Prerequisites

- [Docker](https://www.docker.com/)
- [VS Code](https://code.visualstudio.com/) with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Git](https://git-scm.com/)

## Project Structure Options

### Option 1: Single Repository (Recommended)

Keep DevContainer config, backend, and frontend in one Git repository.

**Best for:**

- Version environment and code together
- Simpler repository management

#### Setup Steps

1. Create repository from template:

   ```bash
   # Click "Use this template" on GitHub, then clone:
   git clone git@github.com:your-username/your-new-project.git
   ```

2. Open in VS Code:

   ```bash
   code your-new-project
   ```

3. **Important:** When prompted "Reopen in Container?", click **No** first

4. Create your local configuration:

   ```bash
   cp .devcontainer/.env.local.example .devcontainer/.env.local
   # Edit with your Git name/email
   ```

5. Create project folders:

   ```bash
   mkdir backend frontend
   ```

6. Install Symfony:

   ```bash
   symfony new backend --version="7.2.*"
   # or with webapp:
   symfony new backend --version="7.2.*" --webapp
   ```

7. Install frontend (optional):

   ```bash
   npm create vite@latest frontend
   # or: npx create-next-app frontend
   # or: npx create-react-app frontend
   ```

8. Remove nested .git folders:

   ```bash
   rm -rf backend/.git frontend/.git
   ```

9. Commit your setup:

   ```bash
   git add .
   git commit -m "Initial project setup"
   git push
   ```

10. Reopen in Container (Ctrl+Shift+P → "Dev Containers: Reopen in Container")

### Option 2: Separate Repositories

Use DevContainer as a shared environment, with backend/frontend in separate repos.

**Best for:**

- Reusing DevContainer across projects
- Independent versioning of backend/frontend

#### Setup Steps

1. Clone the template (or copy files)
2. Remove `.git` from template root
3. Initialize separate repos in `backend/` and `frontend/`:
   ```bash
   cd backend
   git init
   git remote add origin git@github.com:your-username/backend-repo.git
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```

## Multi-Root Workspaces

The template includes workspace files for better tooling isolation.

### Available Workspaces

| File                      | Purpose                      |
| ------------------------- | ---------------------------- |
| `backend.code-workspace`  | PHP/Symfony development      |
| `frontend.code-workspace` | JavaScript/React development |

### Using Workspaces

1. Open the `.code-workspace` file in VS Code
2. When prompted, reopen in container
3. When prompted about Git repository in parent folders, choose **Yes**

### Benefits

- PHP-CS-Fixer only runs in backend
- ESLint/Prettier only in frontend
- Isolated terminal and settings

## Starting Development Servers

### Backend (Symfony)

```bash
# With HTTPS (after certificate setup):
symfony server:start --listen-ip=0.0.0.0 --port=8000

# Without HTTPS (simpler):
symfony server:start --no-tls --allow-http --listen-ip=0.0.0.0 --port=8000
```

### Frontend

The `--host` flag is required to access from outside the container:

| Framework            | Command                     |
| -------------------- | --------------------------- |
| **Vite**             | `npm run dev -- --host`     |
| **Create React App** | `HOST=0.0.0.0 npm start`    |
| **Next.js**          | `npm run dev -- -H 0.0.0.0` |
| **Nuxt**             | `npm run dev -- -H 0.0.0.0` |
| **Astro**            | `npm run dev -- --host`     |

## Symfony HTTPS Setup

### First Time Setup

1. Inside container, install CA:

   ```bash
   symfony server:ca:install
   ```

2. On **host machine**, trust the certificate:

   **Linux:**

   ```bash
   sudo cp ~/.symfony5/certs/rootCA.pem /usr/local/share/ca-certificates/symfony-ca.crt
   sudo update-ca-certificates
   ```

   **macOS:**

   ```bash
   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/.symfony5/certs/rootCA.pem
   ```

   **Windows:**
   - Navigate to `%USERPROFILE%\.symfony5\certs\`
   - Double-click `rootCA.pem` → Install → "Trusted Root Certification Authorities"

## Accessing Services

| Service  | URL                   | Credentials                                    |
| -------- | --------------------- | ---------------------------------------------- |
| Backend  | http://localhost:8000 | -                                              |
| Frontend | http://localhost:5173 | -                                              |
| Adminer  | http://localhost:8080 | Server: `db`, User: `symfony`, Pass: `symfony` |
| Mailpit  | http://localhost:8025 | -                                              |

## Common Commands

```bash
# Symfony
symfony console make:controller
symfony console doctrine:migrations:migrate
symfony console cache:clear

# Composer
composer require package-name
composer install

# Database
symfony console doctrine:database:create
symfony console make:migration

# Frontend
npm install
npm run build
```
