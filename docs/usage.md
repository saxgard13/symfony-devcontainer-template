# Usage Guide

This guide explains how to set up and use the DevContainer template.

## Prerequisites

- [Docker](https://www.docker.com/)
- [VS Code](https://code.visualstudio.com/) with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Git](https://git-scm.com/)

## Project Types

This DevContainer officially supports the following project structures:

| Type                          | Examples                          | Folders used                                        |
| ----------------------------- | --------------------------------- | --------------------------------------------------- |
| **Backend only**              | Symfony full-stack, REST API only | `project/backend/` only                             |
| **Frontend only**             | Next.js, Nuxt, Astro standalone   | `project/frontend/` only                            |
| **Backend + SPA**             | Symfony API + React/Vue (Vite)    | `project/backend/` + `project/frontend/`            |
| **Backend + SSR**             | Symfony API + Next.js             | `project/backend/` + `project/frontend/`            |

All types use `project.code-workspace` — open the folders you need and ignore the rest.

> **Note:** The `project/frontend/` folder is used for both SPA (Vite) and SSR (Next.js). The rendering strategy determines which Docker Compose file to use in production, not the folder name.

> **Other frameworks (Nuxt, Astro, SvelteKit...):** Development works out of the box with any Node.js framework. For production Docker images, see [Framework Adaptation Guide](framework-adaptation.md).

### Adapting the Workspace File

The `.code-workspace` files point to specific folders. If you use a different folder name, update the workspace:

```json
{
  "folders": [{ "path": "your-folder-name" }]
}
```

Or simply rename/copy the appropriate workspace file.

### Port Usage by Project Type

| Project Type      | Port 8000       | Port 5173/3000      |
| ----------------- | --------------- | ------------------- |
| Symfony API + SPA | Symfony backend | Frontend dev server |
| Full Symfony      | Symfony app     | Not used            |
| Full JavaScript   | Not used        | Next.js/Nuxt/Vite   |

> **Tip:** If you only use one port, the other simply remains unused. No configuration change needed.

> **Note:** Production test uses the same ports as development. Stop the DevContainer before running production tests.

## Repository Options

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

5. **⚠️ Reopen in Container** (REQUIRED before using Symfony CLI and npm):

   Press `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"

   The following steps require Symfony CLI and Node.js, which are only available inside the container.

6. Create project folders (inside container):

   ```bash
   mkdir -p project/backend project/frontend
   ```

7. Install Symfony (inside container):

   ```bash
   symfony new project/backend --version="7.2.*"
   # or with webapp:
   symfony new project/backend --version="7.2.*" --webapp
   ```

8. Install frontend (optional, inside container):

   ```bash
   # Officially supported:
   npm create vite@latest project/frontend       # Vite SPA (recommended)
   npx create-next-app project/frontend         # Next.js SSR
   ```

   > **Other frameworks (Nuxt, Astro, etc.):** Development works out of the box. For production, see [Framework Adaptation Guide](framework-adaptation.md).

9. Remove nested .git folders (inside container):

   ```bash
   rm -rf project/backend/.git project/frontend/.git
   ```

10. Commit your setup (inside container):

    ```bash
    git add .
    git commit -m "Initial project setup"
    git push
    ```

### Option 2: Separate Repositories

Use DevContainer as a shared environment, with project/backend/frontend in separate repos.

**Best for:**

- Reusing DevContainer across projects
- Independent versioning of project/backend/frontend
- Using Claude Code (keep root workspace open for full context)

#### Setup Steps

1. Clone the template (or copy files)
2. Remove `.git` from template root
3. Create `.gitignore` in root to exclude nested repos:
   ```
   # Nested repositories (separate Git repos)
   project/backend/
   project/frontend/
   ```
4. Initialize separate repos in `project/backend/` and `project/frontend/`:
   ```bash
   cd project/backend
   git init
   git remote add origin git@github.com:your-username/backend-repo.git
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```

**💡 Tip for Claude Code:** Keep the root workspace open (`code .`) so Claude Code can see both backend and frontend. You don't need to use `.code-workspace` files - they're optional and mainly useful for IDE tool isolation when working manually.

**⚠️ Note on nested Git repos:** Git automatically ignores directories with their own `.git` folder, but adding them to `.gitignore` makes this explicit and prevents accidental tracking if the nested `.git` folders are removed.

## VS Code Workspace

The template includes workspace files for better tooling isolation.

### Available Workspaces

| File                      | Purpose                                                              |
| ------------------------- | -------------------------------------------------------------------- |
| `project.code-workspace`  | Single entry point for all project types (backend-only, frontend-only, or full-stack) |

### Using Workspaces

1. Open the `.code-workspace` file in VS Code
2. When prompted, reopen in container
3. **Git repository prompt** - The response depends on your repository structure:
   - **Single repository (Monorepo):** Choose **Yes** - The DevContainer config and the `project/` folder (backend, frontend) are all in one Git repo
   - **Separate repositories (Multi-repo):** Choose **No** - Each folder has its own `.git` directory, and the root is not a Git repository

> **Note on `project/CLAUDE.md`:** When using `project.code-workspace`, the `project/CLAUDE.md` file contains global AI context (stack, conventions, architecture) accessible to Claude Code for the entire project.

### When to use each Workspace

- **`project.code-workspace`**: The only workspace file. Opens `project/` as root — navigate `backend/` or `frontend/` as needed. Works for all project types (backend-only, frontend-only, full-stack). Perfect for Claude Code — the AI has immediate access to both backend and frontend context.

### Benefits

- PHP-CS-Fixer only runs in backend
- ESLint/Prettier only in frontend
- Isolated terminal and settings
- Cleaner sidebar without configuration file clutter

### Documentation Structure

For multi-repo projects, organize documentation hierarchically:

**Project-wide documentation** (`project/`):
- `CLAUDE.md` - AI context for Claude Code (global instructions)
- Add your own: `architecture.md`, `api-spec.md`, `conventions.md`

**Backend documentation** (`project/backend/`):
- `README.md` - Quick start
- `docs/setup.md` - Detailed installation
- `docs/database.md` - Database schema & migrations

**Frontend documentation** (`project/frontend/`):
- `README.md` - Quick start
- `docs/setup.md` - Detailed installation
- `docs/components.md` - Component architecture

This approach ensures:
- Claude Code has immediate access to project context
- Each repo maintains its own specific documentation
- No duplication of shared knowledge

## Starting Development Servers

### Backend (Symfony)

```bash
symfony server:start --no-tls --listen-ip=0.0.0.0 --port=8000
```

> For HTTPS in development, use the Caddy reverse proxy — see [HTTPS Guide](https.md).

### Frontend

The `--host` flag is required to access from outside the container:

| Framework   | Command                      |
| ----------- | ---------------------------- |
| **Vite**    | `npm run dev -- --host`      |
| **Next.js** | `npm run dev -- -H 0.0.0.0`  |

> **Other frameworks:** Pass the equivalent `--host 0.0.0.0` flag. VS Code auto-detects and forwards the port automatically.


## Accessing Services

| Service  | URL                   | Credentials                                    |
| -------- | --------------------- | ---------------------------------------------- |
| Backend  | http://localhost:8000 | -                                              |
| Frontend | http://localhost:5173 | -                                              |
| Adminer  | http://localhost:8080 | Server: `db`, User: `symfony`, Pass: `symfony` |
| Mailpit  | http://localhost:8025 | -                                              |

## Code Quality

### Backend (PHP/Symfony)

This template includes support for PHP code style fixing and static analysis:

- **PHP-CS-Fixer** - Automatically fixes code to follow PSR-12 standard
- **PHPStan** - Detects logical errors and type-related issues

**Quick start:**

```bash
cd project/backend

# Auto-fix code style
php-cs-fixer fix src/

# Check code for errors
phpstan analyse src/
```

Both tools are pre-configured with junstyle.php-cs-fixer extension (auto-fix on save).

### Frontend (JavaScript/TypeScript)

Frontend quality tools enforce code standards:

- **ESLint** - Finds code quality problems and suspicious patterns
- **Prettier** - Auto-formats code to maintain consistency
- **TypeScript** - Type checking for JavaScript code

**Quick start:**

```bash
cd project/frontend

# Check for code quality issues
npm run lint

# Auto-fix linting issues
npm run lint:fix

# Check code formatting
npm run format:check

# Auto-format code
npm run format

# Type checking (if using TypeScript)
npm run type-check
```

For complete setup instructions, configuration files, and CI/CD integration, see [**Code Quality Tools**](quality-tools.md).

For GitHub Actions workflow setup (separate workflows for quality, tests, deployment, etc.), see [**GitHub Actions Workflows**](workflows.md).

## Development Tools

### Backend (PHP/Symfony)

Optional tools to enhance your Symfony development experience:

- **Debug Bundle** - Interactive debugging toolbar for inspecting requests
- **Profiler Pack** - Performance analysis and bottleneck detection
- **Maker Bundle** - Code scaffolding (entities, controllers, forms)
- **Test Pack** - PHPUnit testing framework

**Quick start:**

```bash
cd project/backend

# Install development tools
composer require --dev symfony/debug-bundle
composer require --dev symfony/profiler-pack
composer require --dev symfony/maker-bundle
composer require --dev symfony/test-pack

# Generate an entity
symfony console make:entity

# Generate a controller
symfony console make:controller

# Create a test
symfony console make:test

# Run tests
php bin/phpunit
```

The debug toolbar appears automatically at the bottom of every page in development mode.

### Frontend (JavaScript/TypeScript)

Optional tools to enhance your frontend development experience:

- **Jest/Vitest** - Unit and component testing framework
- **Testing Library** - Component testing utilities (works with Jest/Vitest)
- **Storybook** - Component development and documentation
- **Prettier** - Code formatting for consistency

**Quick start:**

```bash
cd project/frontend

# Install testing framework (choose one)
npm install --save-dev vitest @testing-library/react @testing-library/jest-dom

# OR for Jest
npm install --save-dev jest @testing-library/react @testing-library/jest-dom

# Install Prettier (optional, often included by default)
npm install --save-dev prettier

# Run tests
npm test

# Format code
npm run format

# Start Storybook (if installed)
npm run storybook
```

For detailed setup and usage instructions, see [**Development Tools**](development-tools.md).

## Common Commands

### Backend (Symfony)

```bash
# Generate code
symfony console make:controller
symfony console make:entity
symfony console doctrine:migrations:migrate

# Database
symfony console doctrine:database:create
symfony console make:migration

# Cache & tools
symfony console cache:clear

# Composer
composer require package-name
composer install

# Code Quality
php-cs-fixer fix src/                    # Auto-fix code style
php-cs-fixer fix src/ --dry-run --diff   # Preview changes without fixing
phpstan analyse src/                     # Analyze for errors

# Testing
php bin/phpunit
php bin/phpunit tests/Controller/        # Run specific tests
```

### Frontend (JavaScript/React/Vue/etc)

> **Package manager:** All commands below use `npm` but you can use `pnpm` or `yarn` instead — they are pre-installed in the dev container. Replace `npm install` → `pnpm install` / `yarn`, and `npm run` → `pnpm run` / `yarn`.

```bash
# Dependencies
npm install
npm install package-name --save-dev

# Development
npm run dev                      # Start dev server
npm run build                    # Build for production

# Code Quality
npm run lint                     # Check for code issues
npm run lint:fix                 # Auto-fix linting issues
npm run format                   # Format code with Prettier
npm run format:check             # Check if code is formatted
npm run type-check               # Type checking (TypeScript)

# Testing
npm test                         # Run tests
npm test -- --coverage           # Tests with coverage report
npm test -- --watch              # Watch mode

# Storybook
npm run storybook                # Start Storybook dev server
npm run build-storybook          # Build static Storybook site
```
