# Symfony DevContainer Template

This repository provides a ready-to-use development environment for Symfony using DevContainers, ideal for consistent local setups and onboarding.

> **Note:** This template is intended for **local development and testing only**. While it includes production-like configurations (Dockerfile.apache.prod, security headers, etc.), these are provided to help you test your application in an environment similar to production. **Do not use this setup directly in a real production environment** without proper security audits, hardened configurations, and infrastructure best practices (load balancing, monitoring, backups, etc.).

## Features

- PHP with essential extensions
- Composer
- Symfony CLI
- MySQL (with preconfigured environment), you can switch to PostgreSQL if needed
- Redis for caching and sessions
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

### Production Database Access (SSH Tunnel)

In production, the database should **never be exposed publicly**. Use an SSH tunnel to access it securely from your local machine.

**1. Create the tunnel (from your local machine):**
```bash
# Run this on YOUR LOCAL PC, not on the server
ssh -L 3307:db:3306 user@your-server.com
#      │    │   │
#      │    │   └── MySQL port in Docker container
#      │    └────── Docker service name
#      └─────────── Local port on your PC (your choice)
```

**2. Connect via CLI (from your local machine, in another terminal):**
```bash
mysql -h 127.0.0.1 -P 3307 -u symfony_prod -p
```

**3. Connect via GUI tools** (DBeaver, TablePlus, MySQL Workbench):

| Setting  | Value           |
|----------|-----------------|
| Host     | `127.0.0.1`     |
| Port     | `3307`          |
| User     | `symfony_prod`  |
| Password | your password   |

The tunnel encrypts all traffic and requires SSH authentication. Close the SSH session to terminate access.

### SSH Key Setup (Required for Tunnel)

SSH keys provide secure, password-less authentication. The private key stays on your PC, the public key goes to the server.

**1. Generate keys (on your local PC):**
```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
# Press Enter for default path, then set a passphrase (recommended)
```

**2. Copy public key to server:**
```bash
ssh-copy-id user@your-server.com
# Or manually:
cat ~/.ssh/id_ed25519.pub | ssh user@your-server.com "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

**3. Test the connection:**
```bash
ssh user@your-server.com
# Should connect without password (only passphrase if set)
```

**4. (Essential) Disable password authentication on server:**
```bash
# Edit /etc/ssh/sshd_config on the server
PasswordAuthentication no
PermitRootLogin no
# Then restart: sudo systemctl restart sshd
```

| File | Location | Share? |
|------|----------|--------|
| `~/.ssh/id_ed25519` (private) | Local PC only | **NEVER** |
| `~/.ssh/id_ed25519.pub` (public) | Local PC + Server | Yes |

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

## Redis Cache

Redis is included by default for caching and session storage.

### Configuration in Symfony

**1. Install the Redis adapter:**

```bash
composer require symfony/cache
```

**2. Add to your `.env`:**

```env
REDIS_URL=redis://redis:6379
```

**3. Configure cache in `config/packages/cache.yaml`:**

```yaml
framework:
    cache:
        app: cache.adapter.redis
        default_redis_provider: '%env(REDIS_URL)%'
```

**4. (Optional) Use Redis for sessions in `config/packages/framework.yaml`:**

```yaml
framework:
    session:
        handler_id: '%env(REDIS_URL)%'
```

### Usage Example

```php
use Symfony\Contracts\Cache\CacheInterface;

class ProductController extends AbstractController
{
    #[Route('/products', name: 'product_list')]
    public function list(CacheInterface $cache, ProductRepository $repository): Response
    {
        // First call: executes the query and stores result in Redis
        // Next calls: returns cached data (much faster)
        $products = $cache->get('products_list', function() use ($repository) {
            return $repository->findAllWithCategories(); // Expensive query
        });

        return $this->json($products);
    }
}
```

### Cache Invalidation

The cache doesn't know when your data changes. You need to handle invalidation:

**1. TTL (Time To Live)** - Cache expires automatically:

```php
use Symfony\Contracts\Cache\ItemInterface;

$products = $cache->get('products_list', function(ItemInterface $item) use ($repository) {
    $item->expiresAfter(3600); // Expires after 1 hour
    return $repository->findAll();
});
```

**2. Manual invalidation** - Delete cache when data changes:

```php
// In your controller/service that modifies products
public function create(Product $product, CacheInterface $cache): Response
{
    $this->entityManager->persist($product);
    $this->entityManager->flush();

    $cache->delete('products_list'); // Invalidate cache

    return $this->json($product);
}
```

**3. Doctrine Event Listener** - Automatic invalidation:

```php
// src/EventListener/CacheInvalidator.php
use Doctrine\ORM\Events;
use Doctrine\Bundle\DoctrineBundle\Attribute\AsDoctrineListener;

class CacheInvalidator
{
    public function __construct(private CacheInterface $cache) {}

    #[AsDoctrineListener(event: Events::postPersist, entity: Product::class)]
    #[AsDoctrineListener(event: Events::postUpdate, entity: Product::class)]
    #[AsDoctrineListener(event: Events::postRemove, entity: Product::class)]
    public function invalidate(): void
    {
        $this->cache->delete('products_list');
    }
}
```

| Strategy | Use case |
|----------|----------|
| **TTL** | Data that can be slightly stale (stats, public lists) |
| **Manual** | Critical data, few modification points |
| **Event Listener** | Many modification points, need automation |

### Disable Redis

If you don't need Redis, remove `docker-compose.redis.yml` from the `dockerComposeFile` array in `devcontainer.json`.

## Security

### Credentials Security

The database credentials provided in this template are generic values intended for local development only. They should never be used in production or exposed in any publicly accessible environment.

Database credentials use environment variable substitution with default values:

```yaml
MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-roots}
MYSQL_USER: ${MYSQL_USER:-symfony}
MYSQL_PASSWORD: ${MYSQL_PASSWORD:-symfony}
```

This means:
- If the environment variable is defined → use its value
- Otherwise → use the default value (e.g., `roots`, `symfony`)

To customize these values, define them in `.devcontainer/.env` or `.devcontainer/.env.local` (untracked).

### Apache Security Headers

The Apache configuration (`.devcontainer/config/apache/vhost.conf`) includes security headers to protect against common web vulnerabilities:

| Header | Protection |
|--------|------------|
| `X-Frame-Options: DENY` | Clickjacking |
| `X-Content-Type-Options: nosniff` | MIME type sniffing |
| `X-XSS-Protection: 1; mode=block` | XSS (legacy browsers) |
| `Referrer-Policy: strict-origin-when-cross-origin` | URL information leakage |
| `Content-Security-Policy` | XSS, code injection |

### Apache HTTPS Configuration (Production)

The current `vhost.conf` is configured for HTTP (port 80). For production with HTTPS, you would need to add a separate VirtualHost for port 443:

```apache
<VirtualHost *:443>
    ServerName your-domain.com
    DocumentRoot /var/www/html/public

    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/your-cert.crt
    SSLCertificateKeyFile /etc/ssl/private/your-key.key

    <Directory /var/www/html/public>
        AllowOverride All
        Require all granted
    </Directory>

    # Security Headers (same as HTTP + HSTS)
    Header always set X-Frame-Options "DENY"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"

    # HSTS - Only for HTTPS!
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

**Note:** For local development, we recommend using `symfony serve` which handles HTTPS automatically (see [Symfony Local Web Server](#symfony-local-web-server)). The Apache HTTPS configuration above is intended for production deployments with real SSL certificates (e.g., Let's Encrypt).

### Docker Ignore

A `.dockerignore` file is configured to prevent sensitive or unnecessary files from being included in production Docker images:

- `.git`, `.gitignore` - Version control
- `.env.local`, `.env.*.local` - Local secrets
- `node_modules/`, `vendor/` - Dependencies (reinstalled in container)
- `var/cache/`, `var/log/` - Temporary files
- IDE configurations (`.vscode/`, `.idea/`)

## [bug] Xdebug Configuration

To enable step-debugging with Xdebug inside the container, you must tell Xdebug how to
reach your host machine. This requires setting the correct host IP address.

### [search] 1. Find your Host IP Address

Depending on your host operating system, the value of `xdebug.client_host` may vary.

#### [ok] Recommended default (for most macOS & Windows users):

Use the special Docker internal host:

```ini
xdebug.client_host=host.docker.internal
```

This works on:

- macOS (Docker Desktop)
- Windows (Docker Desktop)

#### [linux] For Linux hosts (or Linux VMs):

Linux does **not** support `host.docker.internal` by default. You must find your host IP
manually.

From your Linux host or Linux VM, run:

```bash
ip a | grep inet
```

Look for a line like:

```
inet 10.0.2.15/24 brd ...
```

Use the IP you find (e.g. `10.0.2.15`).

### [gear] 2. Set the IP in configuration files

#### `.devcontainer/config/php.ini` (or `xdebug.ini`)

```ini
; Update this value!
xdebug.client_host=host.docker.internal ; or your Linux IP
xdebug.client_port=9003
```

#### `.vscode/launch.json`

```json
{
  "name": "Listen for Xdebug",
  "type": "php",
  "request": "launch",
  "port": 9003,
  "env": {
    "XDEBUG_MODE": "debug,develop",
    "XDEBUG_CONFIG": "client_host=host.docker.internal client_port=9003"
  }
}
```

If you're on Linux, replace `host.docker.internal` with the IP found in step 1 (e.g.
`10.0.2.15`).

### [rebuild] 3. Rebuild the DevContainer

To apply changes, rebuild the container:

- Open the Command Palette (Ctrl+Shift+P)
- Select: `Dev Containers: Rebuild Container`

### [ok] Done!

Once this is configured:

- You can set breakpoints in your PHP files
- Run your app inside the container
- VS Code will catch the debug session as expected

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
symfony server:start --no-tls --port=8000 --allow-http --listen-ip=0.0.0.0

# Terminal (Example with Vite in the frontend workspace window)
npm run dev -- --host
```

When running frontend development servers inside a Docker container, the default behavior of many tools is to bind to `localhost`, which makes them inaccessible from outside the container. To fix this, we need to explicitly bind to `0.0.0.0`, so the server listens on all network interfaces.

Below are the appropriate dev commands for popular frontend frameworks:

| Framework                  | Docker-compatible dev command |
| -------------------------- | ----------------------------- |
| **Vite**                   | `npm run dev -- --host`       |
| **Create React App (CRA)** | `HOST=0.0.0.0 npm start`      |
| **Next.js**                | `npm run dev -- -H 0.0.0.0`   |
| **Nuxt**                   | `npm run dev -- -H 0.0.0.0`   |
| **Astro**                  | `npm run dev -- --host`       |

> ⚠️ These commands ensure the dev server is accessible from outside the container (e.g., at `localhost:3000` on your host machine).

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

### HTTPS Support with Shared Certificates

The DevContainer is configured to share Symfony certificates between your host machine and the container via a mounted volume (`~/.symfony5`). This allows HTTPS to work seamlessly.

**First time setup:**

1. Inside the DevContainer, install the Symfony CA:

```bash
symfony server:ca:install
```

2. On your **host machine**, install the generated CA certificate so your browser trusts it:

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
- Double-click on `rootCA.pem` → Install → "Trusted Root Certification Authorities"

**Start the server with HTTPS:**

```bash
symfony server:start --listen-ip=0.0.0.0 --port=8000
```

**Start without HTTPS (simpler for basic development):**

```bash
symfony server:start --allow-http --no-tls --listen-ip=0.0.0.0 --port=8000
```

- `--allow-http` disables the HTTPS enforcement (useful if TLS is not configured).
- `--no-tls` starts the server without HTTPS.
- `--listen-ip=0.0.0.0` makes the server accessible from the host (not just inside the container).

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
| Contexte | URL à utiliser | Notes |
|---------------------------|-----------------------|-------------------------------------|
| Backend container | http://dev:8000 | Nom du service Docker backend |
| Frontend container | http://frontend:5173 | Port par défaut de Vite |
| Navigateur (host machine) | http://localhost:8000 | Pour accéder au backend |
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

## 🔑 Utiliser vos clés SSH dans le DevContainer

Le template monte automatiquement votre dossier ~/.ssh depuis votre machine hôte dans le container, ce qui permet de cloner ou pousser vos dépôts privés sans configuration supplémentaire.

Vérification rapide


```bash
ls -l ~/.ssh        # voir vos clés dans le container
ssh -T git@github.com  # tester l'accès à GitHub
```

✅ Les clés restent privées, elles ne sont jamais ajoutées au projet ni au repository.  
✅ Chaque utilisateur peut conserver ses propres noms de clés (id_rsa, id_ed25519, github, etc.).

## Production Build

A production-like Dockerfile is available at `.devcontainer/Dockerfile.apache.prod`. It uses a multi-stage build for optimized images.

> **Important:** This "production" configuration is designed for **local testing in a production-like environment**, not for actual deployment. Use it to validate your application behaves correctly with production settings (optimized autoloader, no dev dependencies, etc.) before deploying to your real infrastructure.

### Features

- **Multi-stage build**: Separates build dependencies from runtime, resulting in smaller images
- **Optimized layer caching**: Dependencies are installed before copying source code, so they're cached unless `composer.json` changes
- **Security headers**: Apache is preconfigured with security headers
- **Non-root user**: Apache runs as `www-data`

### Build the production image

```bash
docker build -f .devcontainer/Dockerfile.apache.prod -t my-app:prod .
```

### Docker layer caching optimization

The Dockerfile copies dependency files first, then installs dependencies, and finally copies the source code:

```dockerfile
# 1. Copy dependency files (cached if unchanged)
COPY backend/composer.json backend/composer.lock* ./backend/

# 2. Install dependencies (cached if composer.* unchanged)
RUN cd backend && composer install --no-dev --optimize-autoloader

# 3. Copy source code (rebuilt on every code change)
COPY . .
```

This ensures that dependencies are only reinstalled when `composer.json` or `composer.lock` change, not on every code modification.

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
