# Symfony DevContainer Template

This repository provides a ready-to-use development environment for Symfony using DevContainers, ideal for consistent local setups and onboarding.

## Features

- PHP with essential extensions
- Composer
- Symfony CLI
- MySQL (with preconfigured environment), you can switch to PostgreSQL if needed
- Node.js (for assets, Encore, etc. or separate frontend)
- PHP-CS-Fixer preconfigured with PSR-12 rules ()  
  👉 You will need to install php-cs-fixer via composer once symfony is installed, and add a configuration file to the root of the app/ .
- Eslint
  👉 You will need to install Eslint via npm and add a configuration file to the root of the frontend/ or backend/.
- Xdebug, Intelephense, Prettier, Docblocker, and other useful VS Code extensions
- Works out of the box with GitHub Codespaces or locally via Docker and VS Code

## Files Structure

- .devcontainer/: DevContainer configuration files (Dockerfile, docker-compose, settings, setup script, .env, .en.local (create yourself))
- backend/: Your Symfony project directory (you must create it)
- frontend/: your frontend project directory (you must create it). Not necessary if you use a full project symfony without api.
- `.devcontainer/.env` file configures the PHP and Node.js versions, the backend container image name, the ports used, and the project name to avoid conflicts with database names.
- `.devcontainer/.env.local` file modify name and email github
- `.devcontainer/setup.sh` script initializes the development environment by optionally cleaning VS Code server extensions cache, displaying versions of PHP, Symfony, Composer, Node, and npm. It also loads environment variables from `.env.local` and configures Git user name and email if provided.
- The `.devcontainer/ini.sh` script checks if the external Docker network named `devcontainer-network` exists, and creates it if it does not. This shared network allows multiple containers (e.g. Symfony API and React frontend) to communicate seamlessly within the development environment.
- backend.code-workspace: workspace multi-root
- frontend.code-workspace: workspace multi-root

## Requirements

- [Docker](https://www.docker.com/)
- [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Git](https://git-scm.com/) (with name and email configured)
- [Symfony CLI](https://symfony.com/download) (Required to run the Symfony local server with HTTPS support, manage TLS certificates, and streamline development.)

## Database Configuration

- Host: db
- Mysql Port: 3306
- PostgreSQL Port: 5432
- Username: symfony
- Password: symfony
- Database: <project_name>\_db
  This ensures consistency and avoids conflicts between projects. The `<project_name>` value is defined in the `.env` file (via the `PROJECT_NAME` variable).

## How to Switch the Database Engine

To change the database engine used by the project (e.g., from MySQL to PostgreSQL or MariaDB), you need to update a few configurations:

**Modify dockerComposeFile in devcontainer.json:**

Replace the default database compose file to the one matching your chosen database engine. For example, to use PostgreSQL instead of MySQL or MariaDB:

```bash
"dockerComposeFile": [
  "docker-compose.yml",
  "docker-compose.postgre.yml"
],
```

**Update the DATABASE_URL environment variable in your Docker Compose file:**

Change the connection URL to reflect the selected database engine, user credentials, port, and server version. Examples:

MySQL or MariaDB:

```bash
DATABASE_URL: mysql://symfony:symfony@db:3306/${PROJECT_NAME}_db?serverVersion=${SERVER_VERSION}
```

PostgreSQL:

```bash
DATABASE_URL: pgsql://symfony:symfony@db:5432/${PROJECT_NAME}_db
```

Note: For PostgreSQL, the serverVersion parameter is not required and can be omitted.

**Set the appropriate variables in your .env file:**

Make sure you set the corresponding variables for your database engine, image, and version. For example:

```bash
DB_IMAGE=postgres:16
SERVER_VERSION=   # Leave empty for PostgreSQL
```

Or for MySQL:

```bash
DB_IMAGE=mysql:8.3
SERVER_VERSION=8.3
```

Or for MariaDB:

```bash
DB_IMAGE=mariadb:10.11
SERVER_VERSION=mariadb-10.11
```

By following these steps, you can easily switch between MySQL, MariaDB, and PostgreSQL in your development environment.

## Credentials Security in This Devcontainer

The database credentials provided in this template are generic values intended for local development only.

They should never be used in production or exposed in any publicly accessible environment.

To customize these values, it is recommended to use environment variables or a local (untracked) .env file, which you can configure according to your needs.

This devcontainer is designed to run in an isolated environment and does not expose databases externally, minimizing security risks.

## 🔧 How to use (example with Symfony & multi-root workspaces)

This DevContainer template supports two flexible project structures: single repository and separate repositories, both compatible with multi-root workspaces in VS Code. This makes it easy to manage a full-stack app (e.g. Symfony + React) while keeping backend and frontend cleanly separated.

### Option 1: Single Repository — DevContainer + Symfony + React in One Git Repo

This option keeps the DevContainer config, backend, and frontend in the same Git repository.

Ideal when:

    You want to version both your environment and code together.
    You want to avoid managing multiple repos.

**Steps:**

- Click "Use this template" on GitHub to create a new repository based on this template.
- Clone your new repository locally:

```bash
git clone git@github.com:your-username/your-new-project.git
```

- Open project folder with vs code
- Do not reopen in container when prompted
- When prompted:
    ❌ Don’t reopen in container immediately.
    ✅ If you see:
    “A Git repository was found in the parent folders. Would you like to open it?”
    👉 Choose “Yes” to use the root Git repository (recommended).
- Create .devcontainer/.env.local with your github config (name and email)
- Change .devcontainer/.env configuration (PHP version etc.)
- Change .devcontainer/config/php.ini (if you want)- 
- Create backend and/or frontend folder

```bash
mkdir backend frontend
```

- Install Symfony in the backend/ folder from the VS Code terminal

```bash
symfony new backend --version="7.2.*"
```

or with web stack

```bash
symfony new backend --version="7.2.*" --webapp
```
- Install your frontend app (React, Next.js...) in frontend/:

```bash
npx create-react-app frontend
# or with Vite
npm create vite@latest frontend
# or with Next.js
npx create-next-app frontend
```

- Both Symfony and frontend tools will likely initialize .git folders. To avoid nested git repositories, remove .git folders in backend and frontend after install :

```bash
rm -rf backend/.git frontend/.git
```

- Your first commit

```bash
git add .
git commit -m "Initial project setup"
git push
```

✅ This structure keeps one single Git history for your full-stack app, while allowing VS Code to treat backend and frontend as independent projects with their own tools and settings


#### Multi-root workspaces

To enhance developer experience, this template includes two multi-root workspace files:

- backend.code-workspace → For your Symfony API.
- frontend.code-workspace → For your React/Next.js app.

Each workspace isolates tooling like PHP-CS-Fixer, ESLint, Prettier, etc. inside the corresponding subfolder (/workspace/backend or /workspace/frontend).

**Steps:**

- Open each `.code-workspace` file in its own window.
- Open the DevContainer in both windows when prompted or open the DevContainer via the bottom-left blue button (>< symbol).
- - When prompted:
  “A Git repository was found in the parent folders. Would you like to open it?”
  👉 Choose Yes, so the workspace remains tied to your main Git repository at /workspace.
- Use the following commands in the corresponding terminals:

```bash
# Terminal (Example in the backend workspace window)
symfony server:start --no-tls --port=8000 --allow-http --listen=0.0.0.0

# Terminal (Example in the frontend workspace window)
npm run dev -- --host
```

You can now develop your backend and frontend in parallel.


### Option 2 : Separate Repositories: Symfony App Only

Use this if you want to reuse the DevContainer setup across multiple projects and version only your backend or frontend code.

(Same steps as above, but no Git nesting — each subproject lives in its own repo. You can delete .git from the template, then git init inside backend/ or frontend/ as needed.)

- In backend/ and frontend/ folders Initialize your own Git repo:

```
cd backend
git remote add origin git@github.com:your-username/your-repo.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

## Symfony Local Web Server

This project uses the [Symfony CLI](https://symfony.com/download) to run the local web server for development.

To access the application in your browser with HTTPS support:

**Install Symfony CLI on your host machine**

This is required to enable TLS support and trusted HTTPS connections.  
➜ Run `sudo symfony server:ca:install` **on the host**, not in the container.

**Start the server inside the container**

From the DevContainer terminal, run:

```bash
symfony server:start --listen-ip=0.0.0.0 --port=8000 
```

without https :

```bash
symfony server:start --allow-http --no-tls --listen-ip=0.0.0.0 --port=8000 
```

- --allow-http disables the HTTPS enforcement (useful if TLS is not configured).
- --no-tls starts the server without HTTPS (you can omit this if TLS is installed).
- --listen-ip=0.0.0.0 makes the server accessible from the host (not just inside the container).


## 🔁 Backend (symfony) ↔ Frontend (example : vite) Communication (CORS, URLs, Docker)

NOT TESTED YET (IN PROGRESS)

When using a full-stack architecture with Symfony as the backend (API) and React as the frontend (SPA), you need to configure CORS, environment variables, and URLs to ensure both can communicate properly—especially inside Docker containers.

    🧪 Note: This setup assumes you're using Vite for the frontend, which runs on port 5173 by default. If you're using Next.js, Create React App, or another framework, be sure to replace 5173 with the appropriate internal port (e.g. 3000 for Next.js). And change .env configuration from your devcontainer :  FRONTEND_INTERNAL_PORT, you can keep 5173 for FRONTEND_LOCALHOST_PORT

### 🔐 1. Configure CORS in Symfony

Install and configure nelmio/cors-bundle if not already present:

```bash
composer require nelmio/cors-bundle
```

Then edit your config/packages/nelmio_cors.yaml like so:

```bash
nelmio_cors:
    defaults:
        allow_origin: ['http://frontend:5173']
        allow_headers: ['Content-Type', 'Authorization']
        allow_methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
        max_age: 3600
        supports_credentials: true
    paths:
        '^/': ~
```

This tells Symfony to accept cross-origin requests from the frontend container, which runs on http://frontend:5173 inside the Docker network.

### 🌍 2. Docker Internal Hostnames

When services are in the same Docker network (e.g. app-network), they can reach each other via service names:

    frontend can call http://localhost:8000 (if accessing from browser)
    frontend can call http://dev:8000 from inside the container (e.g. Node.js SSR)
    backend can allow CORS from http://frontend:5173

Summary of internal names:
| Contexte                   | URL à utiliser        | Notes                               |
|---------------------------|-----------------------|-------------------------------------|
| Backend container         | http://dev:8000       | Nom du service Docker backend       |
| Frontend container        | http://frontend:5173  | Port par défaut de Vite             |
| Navigateur (host machine) | http://localhost:8000 | Pour accéder au backend             |
| Navigateur (host machine) | http://localhost:5173 | Pour accéder au frontend    


⚠️ Important: Changing Frontend Frameworks (Vite → Next.js, etc.)
If you switch from Vite (default port 5173) to another frontend framework like Next.js (default port 3000), make sure to update the following:
    FRONTEND_INTERNAL_PORT in .devcontainer/.env
    CORS_ALLOW_ORIGIN in your Symfony environment (.env, .env.local)
    Any Docker-related config that references frontend internal ports
    Your Symfony nelmio_cors.yaml (or make sure it reads from the env variable)
Failure to update these may result in broken communication between frontend and backend due to CORS errors or wrong container routing.


### ⚙️ 3. Environment Configuration

In your React frontend, create a .env file:

```bash
VITE_API_URL=http://localhost:8000/api
```

Inside your frontend code (e.g. axios config or fetch), use:

```bash
const response = await fetch(`${import.meta.env.VITE_API_URL}/products`);
```

- If both frontend and backend run in the same container: localhost will work.
- If they run in separate containers: use internal Docker hostnames like http://dev:8000 or http://backend:8000.


### 🌐 4. CORS_ALLOW_ORIGIN via Symfony Environment

To dynamically configure CORS without hardcoding it in nelmio_cors.yaml, set this in .env or .env.local:

```bash
# Use the same port as FRONTEND_INTERNAL_PORT defined in the devcontainer .env file
CORS_ALLOW_ORIGIN=http://frontend:5173 
```

Then in nelmio_cors.yaml, reference the environment variable:

```bash
allow_origin: ['%env(CORS_ALLOW_ORIGIN)%']
```

✅ This way, the CORS config can be adapted depending on dev/staging/prod environments.


## 🚀 Possible Improvements

Suggestions for enhancing this template further:

    Optional Redis, PostgreSQL, or RabbitMQ containers

    GitHub Actions CI/CD pipeline example (lint, test, build)

    Makefile for common development commands (make build, make lint, etc.)

    Provide devcontainer.json features for faster onboarding

    Allow custom project scaffolding (e.g., symfony new options passed as arguments)
    
Credits

Created by saxgard13

Let me know if you want a French version, badges, images, or a GitHub Actions section added too.
