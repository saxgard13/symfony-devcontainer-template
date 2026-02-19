# Advanced Usage & Customization

This guide covers scenarios **not directly supported** by the template, with examples and key modifications needed.

> **Before reading:** Make sure you understand the template's [scope and limitations](production.md#scope--limitations).

---

## 1. Backend Server Alternatives for Symfony

### PHP-FPM + Nginx as Reverse Proxy

**When to use:**

- Single entry point for both backend and frontend (same port, same HTTPS)
- HTTPS termination at the Nginx level without touching other containers
- Better performance for high concurrency
- Lower memory footprint than Apache + mod_php

> **Default setup:** The template uses Apache (`Dockerfile.apache.prod`). PHP-FPM + Nginx is an advanced alternative for a more production-like setup.

---

#### Dockerfile.phpfpm.prod

```dockerfile
ARG PHP_VERSION=8.3
ARG NODE_VERSION=22

# Stage 1: Composer dependencies
FROM php:${PHP_VERSION}-cli AS composer-builder

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /www

COPY backend/composer.json backend/composer.lock* ./backend/

RUN cd backend && composer install --no-dev --optimize-autoloader --no-interaction --no-progress --no-scripts

COPY backend/ ./backend/

RUN cd backend && composer dump-autoload --optimize --no-dev \
    && if [ -f bin/console ]; then php bin/console cache:warmup --env=prod --no-debug; fi

# Stage 2: Node.js assets builder (only for Webpack Encore)
FROM node:${NODE_VERSION}-alpine AS assets-builder

WORKDIR /build

COPY backend/ ./backend/

RUN if [ -f "backend/package.json" ]; then \
        echo "==> Building Webpack Encore assets..." && \
        cd backend && \
        if [ -f yarn.lock ]; then yarn install --frozen-lockfile && yarn build; \
        elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile && pnpm build; \
        else npm ci && npm run build; fi; \
    else \
        echo "==> No Encore assets to build (optional)" && mkdir -p /build/backend/public; \
    fi

# Stage 3: PHP-FPM runtime (no Xdebug in prod)
FROM php:${PHP_VERSION}-fpm-alpine

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_mysql opcache intl gd bcmath zip

COPY .devcontainer/config/php.ini.prod /usr/local/etc/php/php.ini

COPY --from=composer-builder --chown=www-data:www-data /www/backend /var/www/backend
COPY --from=assets-builder --chown=www-data:www-data /build/backend/public /var/www/backend/public

RUN mkdir -p /var/www/backend/public/uploads && chown www-data:www-data /var/www/backend/public/uploads

WORKDIR /var/www/backend
EXPOSE 9000
CMD ["php-fpm"]
```

---

#### config/nginx/security_headers.conf

Extract security headers into a dedicated snippet to avoid the Nginx inheritance trap:

> **Important — Nginx `add_header` scope:** If a `location` block defines its own `add_header` (e.g. `Cache-Control`), it **stops inheriting** headers from the parent `server` block. Using a separate `include` file and calling it in every `location` that needs headers is the reliable solution.

```nginx
# .devcontainer/config/nginx/security_headers.conf
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
```

#### config/nginx/symfony.prod.conf

Two variants depending on your project type:

**Variant A — Symfony API + Next.js SSR (two containers):**

```nginx
server {
    listen 80;
    server_name localhost;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate     /etc/nginx/certs/localhost.crt;
    ssl_certificate_key /etc/nginx/certs/localhost.key;

    # Symfony backend: all requests to /api/ go to PHP-FPM
    location /api/ {
        include /etc/nginx/security_headers.conf;

        root /var/www/backend/public;
        try_files $uri /index.php$is_args$args;

        location ~ \.php$ {
            include /etc/nginx/security_headers.conf;
            fastcgi_pass phpfpm:9000;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param SERVER_NAME $host;
            fastcgi_param HTTP_AUTHORIZATION $http_authorization; # Required for JWT Bearer
        }
    }

    # Frontend: all other requests proxied to the Node.js container
    location / {
        include /etc/nginx/security_headers.conf;
        proxy_pass http://frontend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

**Variant B — Symfony API + Vite SPA (static files, no frontend container):**

```nginx
server {
    listen 80;
    server_name localhost;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate     /etc/nginx/certs/localhost.crt;
    ssl_certificate_key /etc/nginx/certs/localhost.key;

    # Symfony backend
    location /api/ {
        include /etc/nginx/security_headers.conf;

        root /var/www/backend/public;
        try_files $uri /index.php$is_args$args;

        location ~ \.php$ {
            include /etc/nginx/security_headers.conf;
            fastcgi_pass phpfpm:9000;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param HTTP_AUTHORIZATION $http_authorization; # Required for JWT Bearer
        }
    }

    # SPA: serve built static files, fallback to index.html for client-side routing
    location / {
        include /etc/nginx/security_headers.conf;
        root /var/www/frontend/dist;
        try_files $uri $uri/ /index.html;
    }
}
```

---

#### docker-compose.phpfpm.prod.yml

```yaml
services:
  phpfpm:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile.phpfpm.prod
    environment:
      APP_ENV: prod
      DATABASE_URL: mysql://symfony:symfony@db:3306/${PROJECT_NAME}_db
    depends_on:
      db:
        condition: service_healthy
    networks:
      - app-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./.devcontainer/config/nginx/symfony.prod.conf:/etc/nginx/conf.d/default.conf:ro
      - ./.devcontainer/config/nginx/security_headers.conf:/etc/nginx/security_headers.conf:ro
      - app-public:/var/www/backend/public:ro
      - ./.devcontainer/certs:/etc/nginx/certs:ro
    depends_on:
      - phpfpm
    networks:
      - app-network

  # Only needed for Symfony API + Next.js SSR (Variant A)
  frontend:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile.node.prod
    environment:
      NODE_ENV: production
    networks:
      - app-network

  db:
    extends:
      file: docker-compose.mysql.yml
      service: db
    networks:
      - app-network

volumes:
  app-public:

networks:
  app-network:
    driver: bridge
```

---

#### HTTPS: Generating a self-signed certificate

```bash
mkdir -p .devcontainer/certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout .devcontainer/certs/localhost.key \
  -out .devcontainer/certs/localhost.crt \
  -subj "/CN=localhost"
```

> **For browser-trusted local HTTPS**, use [mkcert](https://github.com/FiloSottile/mkcert) instead — it generates certificates signed by a local CA that your browser trusts without security warnings:
>
> ```bash
> mkcert -install
> mkcert -key-file .devcontainer/certs/localhost.key \
>        -cert-file .devcontainer/certs/localhost.crt \
>        localhost 127.0.0.1
> ```

---

#### Architecture Overview

```
Browser (HTTPS :443)
        │
      Nginx  ← SSL termination
   ┌────┴────┐
   │         │
 /api/*      /*
PHP-FPM    Node.js     ← SSR (Variant A)
(Symfony)  (Next.js)
                       or static files  ← SPA (Variant B)
```

#### Comparison: Apache vs PHP-FPM + Nginx

| Feature                   | Apache (default)  | PHP-FPM + Nginx         |
|---------------------------|-------------------|-------------------------|
| Setup complexity          | Simple            | More complex            |
| Frontend routing          | Separate port     | Same port, same Nginx   |
| HTTPS termination         | Per-service       | Single point            |
| Performance (concurrency) | Moderate          | Better                  |
| Memory footprint          | Higher            | Lower                   |

> **Bottom line:** Apache is the default for its simplicity. PHP-FPM + Nginx is worth it when you want a unified HTTPS entry point for both backend and frontend in a prod-like test environment.

---

### Adding HTTPS to the Existing Apache Setup (Nginx as SSL Terminator)

If you want HTTPS without replacing Apache or touching your existing Dockerfiles, add a lightweight Nginx container **purely for SSL termination** in front of your existing services.

**Apache and Node.js containers stay completely unchanged.**

> This is simpler than the PHP-FPM + Nginx approach: everything goes through `proxy_pass`, so there is no FastCGI complexity and all headers (including `Authorization: Bearer`) are forwarded automatically.

---

#### config/nginx/ssl-proxy.conf

```nginx
server {
    listen 80;
    server_name localhost;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate     /etc/nginx/certs/localhost.crt;
    ssl_certificate_key /etc/nginx/certs/localhost.key;

    # Security Headers
    include /etc/nginx/security_headers.conf;

    # Symfony backend (Apache container)
    location /api/ {
        proxy_pass http://apache:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        # proxy_pass forwards all headers including Authorization: Bearer automatically
    }

    # Frontend (Node.js container for SSR, or remove if SPA served separately)
    location / {
        proxy_pass http://frontend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

> **`security_headers.conf`** — create the same snippet as described above. At the `server` level, `include` works without the inheritance problem **as long as no child `location` has its own `add_header`**. Since all locations here only use `proxy_set_header` (not `add_header`), putting the include once at server level is sufficient.

---

#### docker-compose.ssl-proxy.yml

Add this alongside your existing `docker-compose.prod.yml`:

```yaml
services:
  nginx-proxy:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./.devcontainer/config/nginx/ssl-proxy.conf:/etc/nginx/conf.d/default.conf:ro
      - ./.devcontainer/config/nginx/security_headers.conf:/etc/nginx/security_headers.conf:ro
      - ./.devcontainer/certs:/etc/nginx/certs:ro
    depends_on:
      - apache
      - frontend
    networks:
      - app-network

  apache:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile.apache.prod
    # No ports exposed directly — Nginx is the only entry point
    environment:
      APP_ENV: prod
      DATABASE_URL: mysql://symfony:symfony@db:3306/${PROJECT_NAME}_db
    depends_on:
      db:
        condition: service_healthy
    networks:
      - app-network

  frontend:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile.node.prod
    # No ports exposed directly
    environment:
      NODE_ENV: production
    networks:
      - app-network

  db:
    extends:
      file: docker-compose.mysql.yml
      service: db
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

> **Note:** Apache and Node.js no longer expose ports directly — only Nginx does. Containers communicate internally via service names (`apache`, `frontend`) on the Docker network.

---

#### Architecture Overview

```
Browser (HTTPS :443)
        │
   Nginx proxy  ← SSL termination only, no FastCGI
   ┌─────┴──────┐
   │            │
 /api/*         /*
Apache        Node.js
(unchanged)  (unchanged)
```

#### Comparison with PHP-FPM + Nginx

| | Nginx SSL terminator | PHP-FPM + Nginx |
|--|---------------------|-----------------|
| Existing Dockerfiles | Unchanged | Replaced |
| Nginx config complexity | Simple (proxy_pass only) | Complex (FastCGI + proxy_pass) |
| Authorization header | Automatic | Requires `HTTP_AUTHORIZATION` |
| Performance | Slightly lower | Better |
| When to use | Add HTTPS quickly | Full production-like architecture |

---

### Apache + PHP-FPM (Instead of mod_php)

**When to use:**

- Need Apache modules (mod_rewrite, etc.)
- Prefer FPM separation for debugging
- Better resource management

**Key changes:**

1. In Dockerfile: Use `php:8.3-fpm-alpine` instead of `php:8.3-apache`
2. Configure Apache to proxy requests to FPM via FastCGI
3. Separate services in compose file

**Quick example:**

```dockerfile
# Stage 3: PHP-FPM
FROM php:8.3-fpm-alpine
RUN docker-php-ext-install pdo_mysql opcache
COPY backend/ /app

# Stage 4: Apache
FROM php:8.3-apache
RUN a2enmod proxy_fcgi setenvif
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions bcmath intl
COPY config/apache/symfony-fpm.conf /etc/apache2/sites-available/000-default.conf
COPY --from=3 /app /var/www/html
```

---

## 2. Repository Structure Alternatives

### Multi-repo (Separate Backend/Frontend)

**Challenge:** You have separate repositories for backend and frontend, and need them to communicate.

#### Solution A: Docker Compose with Networking (Recommended for Production)

Create a root-level `docker-compose.multi-repo.yml` that orchestrates both repos:

```yaml
version: "3.8"

services:
  backend:
    build:
      context: ../backend-repo # Path to backend repository
      dockerfile: .devcontainer/Dockerfile.apache.prod
    ports:
      - "8000:80"
    environment:
      APP_ENV: prod
      DATABASE_URL: mysql://user:pass@db:3306/myapp
    depends_on:
      - db
    networks:
      - app-network

  frontend:
    build:
      context: ../frontend-repo # Path to frontend repository
      dockerfile: Dockerfile.spa.prod # or Dockerfile.node.prod for SSR
    ports:
      - "5173:80" # or 3000 for Next.js/Nuxt
    environment:
      VITE_API_URL: http://backend # Use service name for internal communication
    networks:
      - app-network
    depends_on:
      - backend

  db:
    image: mysql:8.3
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: myapp
    volumes:
      - db-data:/var/lib/mysql
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  db-data:
```

**Key benefits:**

- Containers communicate via service names (`backend`, `frontend`) on the Docker network
- Clean separation of repositories
- Easy to scale or swap services
- Mirrors production architecture

**Usage:**

```bash
docker compose -f docker-compose.multi-repo.yml up -d
# Access: http://localhost:8000 (backend), http://localhost:5173 (frontend)
```

---

#### Solution B: Claude Code Multi-Root Workspace (Recommended for Development)

If both repos are cloned locally, use VSCode's **Multi-Root Workspace**:

1. **Create a workspace file** at root level (`project.code-workspace`):

```json
{
  "folders": [
    {
      "name": "Shared Config",
      "path": "./.shared"
    },
    {
      "name": "Backend",
      "path": "./backend"
    },
    {
      "name": "Frontend",
      "path": "./frontend"
    }
  ],
  "settings": {
    "files.exclude": {
      "**/node_modules": true,
      "**/vendor": true
    }
  }
}
```

**Configuration highlights:**
- **`.shared/` first** - Contains `claude.md` and shared documentation
- **Backend & Frontend** - Both repos accessible with separate Git histories
- Claude Code reads `claude.md` automatically for full project context

2. **File structure with centralized configuration:**

```
root/
├── backend/               # Separate repo
│   ├── .git
│   ├── src/
│   ├── .gitignore
│   └── ...
├── frontend/              # Separate repo
│   ├── .git
│   ├── src/
│   ├── .gitignore
│   └── ...
├── .shared/               # ← Centralized config & docs
│   ├── claude.md          # Claude Code context (accessible to both)
│   ├── architecture.md    # Shared architecture documentation
│   ├── api-spec.md        # API endpoints & contracts
│   └── conventions.md     # Code standards for both repos
├── project.code-workspace # ← Root level workspace file
└── docker-compose.multi-repo.yml
```

**Why use `.shared/` folder:**
- **Single source of truth** - Project-wide config in one place
- **Claude Code integration** - Direct access to `claude.md` with full context awareness
- **No duplication** - Architecture and API specs shared by both teams
- **Better organization** - Clean separation between repo-specific and shared concerns

**Recommended documentation structure:**

```
root/
├── .shared/                    # ← Project-wide documentation
│   ├── claude.md              # Claude Code context for entire project
│   ├── architecture.md        # Overall system design
│   ├── api-spec.md            # API endpoints & contracts
│   └── conventions.md         # Code standards for both repos
├── backend/
│   ├── README.md              # Backend setup & quick start
│   ├── docs/
│   │   ├── setup.md           # Detailed backend installation
│   │   ├── database.md        # Database schema & migrations
│   │   └── controllers.md     # Controller patterns
│   └── ...
└── frontend/
    ├── README.md              # Frontend setup & quick start
    ├── docs/
    │   ├── setup.md           # Detailed frontend installation
    │   ├── components.md      # Component architecture
    │   └── state-management.md # Store/Context setup
    └── ...
```

**Documentation responsibilities:**

| Document | Location | Purpose |
|----------|----------|---------|
| **claude.md** | `.shared/` | AI context (what Claude needs to know) |
| **architecture.md** | `.shared/` | System design, how backend & frontend interact |
| **api-spec.md** | `.shared/` | API endpoints, contracts, CORS config |
| **conventions.md** | `.shared/` | Code standards, naming, patterns for both |
| **README.md** (backend) | `backend/` | Quick start: how to install & run backend |
| **README.md** (frontend) | `frontend/` | Quick start: how to install & run frontend |
| **Detailed docs** | `backend/docs/` & `frontend/docs/` | Deep dives specific to each repo |

**Setup `.shared/` folder:**

```bash
mkdir -p .shared
cat > .shared/claude.md << 'EOF'
# Project Context for Claude Code

## Architecture
- **Backend:** Symfony 7.2 API (separate repo)
- **Frontend:** React/Vue SPA (separate repo)
- **Database:** MySQL 8.0

## Key Files
- Backend API: `backend/src/Controller/`
- Frontend Components: `frontend/src/components/`
- Shared Docs: `.shared/`

## Communication
- Frontend calls backend API at `http://localhost:8000`
- CORS enabled for `http://localhost:5173`

## Development Commands
- Backend: `symfony server:start` (port 8000)
- Frontend: `npm run dev -- --host` (port 5173)

## Important Rules
- Always run migrations: `symfony console doctrine:migrations:migrate`
- Frontend builds with: `npm run build`
- Keep API contracts documented in `.shared/api-spec.md`
EOF
```

Both repos remain independent but share project-wide context through `.shared/`.

3. **Open with Claude Code:**

```bash
code project.code-workspace
```

**Key benefits:**

- See and edit both repos in a single VSCode window
- Claude Code (and others IA) available for both repositories
- Easy switching between frontend and backend files
- Unified search across both codebases
- Each repo keeps its own `.git` and `.gitignore`

---

#### Solution C: Git Submodules (If you want monorepo structure)

Keep a single repo but reference both backend and frontend as submodules:

```bash
# In your main repository
git submodule add https://github.com/user/backend.git backend
git submodule add https://github.com/user/frontend.git frontend

# Clone recursively
git clone --recurse-submodules https://github.com/user/main-repo.git
```

Then your Dockerfiles work normally:

```dockerfile
COPY backend/ /app
COPY frontend/ /app
```

**When to use:** You want centralized CI/CD but keep backend/frontend as separate repositories.

---

#### Solution D: Separate Compose Files per Repo

Each repository has its own `docker-compose.yml`:

```bash
# Terminal 1: Backend repo
cd ../backend-repo
docker compose up -d

# Terminal 2: Frontend repo
cd ../frontend-repo
REACT_APP_API_URL=http://localhost:8000 docker compose up -d
```

**Note:** Requires managing multiple terminal sessions and manual API URL configuration.

---

#### Recommendation Matrix

| Use Case               | Solution                               | Reason                                                  |
| ---------------------- | -------------------------------------- | ------------------------------------------------------- |
| **Local development**  | Solution B (Multi-Root Workspace)      | Edit both repos simultaneously, Claude Code integration |
| **Production testing** | Solution A (Docker Compose Networking) | Mirrors production, proper container isolation          |
| **Centralized CI/CD**  | Solution C (Git Submodules)            | Single repo for GitHub Actions workflows                |
| **Simple setup**       | Solution D (Separate Compose)          | No coordination needed, but manual management           |

**Our recommendation:** Use **Solution B for development** + **Solution A for production testing**.

---

#### Bonus: Multi-Root Workspace for Monorepo Organization

Even in a **monorepo structure**, you can use a Multi-Root Workspace to declutter your sidebar and focus on what matters:

**Problem:** Monorepo has many config files that clutter the sidebar:

```
root/
├── .devcontainer/          # ← Clutters sidebar
├── docs/                   # ← Clutters sidebar
├── docker-compose.*.yml    # ← Clutters sidebar
├── backend/                # ← You care about this
├── frontend/               # ← You care about this
└── .gitignore
```

**Solution:** Use a workspace to show only backend + frontend:

```json
{
  "folders": [
    {
      "name": "Backend",
      "path": "backend"
    },
    {
      "name": "Frontend",
      "path": "frontend"
    }
  ]
}
```

**Result:** Sidebar shows only what you're working on, configuration files stay hidden but accessible.

---

### Monorepo with Custom Folder Names

If you use `/api` instead of `/backend`, or `/client` instead of `/frontend`:

**Update Dockerfile COPY paths:**

```dockerfile
# Instead of: COPY backend/
COPY api/

# Instead of: COPY frontend/
COPY client/
```

**Update docker-compose build context if needed.**

---

## 3. Deployment to Real Infrastructure

### VPS (DigitalOcean, Linode, OVH, etc.)

**High-level approach:**

1. **Push image to registry:**

```bash
docker tag my-app:prod myregistry.com/my-app:prod
docker push myregistry.com/my-app:prod
```

2. **On VPS, create docker-compose.yml:**

```yaml
version: "3.8"
services:
  prod:
    image: myregistry.com/my-app:prod
    ports:
      - "80:80"
      - "443:443"
    environment:
      APP_ENV: prod
      DATABASE_URL: mysql://user:pass@db-host:3306/dbname
    volumes:
      - ./uploads:/var/www/html/public/uploads
      - ./certs:/etc/letsencrypt/live
    restart: always

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db-data:/var/lib/mysql

volumes:
  db-data:
```

3. **Set up HTTPS with Let's Encrypt:**

```bash
certbot certonly --standalone -d yourdomain.com
# Copy certs to server
```

4. **Run with systemd:**
   Create `/etc/systemd/system/docker-compose@.service`

```ini
[Unit]
Description=Docker Compose for %i
Requires=docker.service
After=docker.service

[Service]
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down
Restart=always

[Install]
WantedBy=multi-user.target
```

Then:

```bash
systemctl enable docker-compose@myapp
systemctl start docker-compose@myapp
```

---

### Jelastic Cloud (Symfony-Optimized PaaS)

Jelastic supports Docker out-of-the-box. Steps:

1. **Create Jelastic manifest:**

```yaml
# jelastic.yaml
jpsType: install
jpsVersion: '1.4'
name: Symfony + React App
baseUrl: https://github.com/yourname/yourrepo/tree/main/.devcontainer

settings:
  fields:
    - name: PHP_VERSION
      type: string
      default: '8.3'

onInstall:
  - deployFromGit:
      type: docker
      context: .
      dockerfile: Dockerfile.apache.prod
      image: ${env.DOMAIN}-symfony:latest

  - deploy:
      type: docker
      image: node:22-alpine
      context: frontend
      dockerfile: Dockerfile.spa.prod
      image: ${env.DOMAIN}-frontend:latest

  - deploy:
      type: mysql:8.0
      name: database

  - configureSSL:
      deploymentName: ${env.appid}
      cert: letsencrypt
```

2. **Push to Jelastic:**
   - Go to jelastic.com, create account
   - Import project via GitHub
   - Jelastic reads `jelastic.yaml` and deploys automatically

**Benefits:**

- Auto-scaling
- Built-in SSL (Let's Encrypt)
- Container orchestration
- Easy environment management

---

### Heroku (Node.js Frontend Only)

For SSR (Next.js) frontend on Heroku:

1. **Create `Procfile` in frontend folder:**

```
web: npm run start
```

2. **Add `.env.production`** with API URL pointing to Symfony backend

3. **Deploy:**

```bash
heroku login
heroku create your-app
git push heroku main
```

---

### Kubernetes (Minimal Example)

Convert docker-compose to K8s manifests:

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: symfony-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: symfony-api
  template:
    metadata:
      labels:
        app: symfony-api
    spec:
      containers:
        - name: symfony
          image: myregistry.com/symfony:prod
          ports:
            - containerPort: 80
          env:
            - name: APP_ENV
              value: "prod"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: url
          livenessProbe:
            httpGet:
              path: /health
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 10
```

Use tools like **Kompose** to auto-convert compose to K8s:

```bash
kompose convert -f docker-compose.prod.yml
```

---

## 4. CI/CD with GitHub Actions

### Automated Testing, Building & Deploying

Create `.github/workflows/deploy.yml`:

```yaml
name: Build & Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Step 1: Test
  test:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ALLOW_EMPTY_PASSWORD: yes
          MYSQL_DATABASE: test_db
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: "8.3"
          extensions: pdo_mysql, intl, gd

      - name: Install Composer dependencies
        run: |
          cd backend
          composer install --no-progress --prefer-dist

      - name: Run backend tests
        run: |
          cd backend
          php bin/phpunit

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: "22"

      - name: Install frontend dependencies
        run: |
          cd frontend
          npm ci

      - name: Build frontend
        run: |
          cd frontend
          npm run build

      - name: Lint frontend
        run: |
          cd frontend
          npm run lint

  # Step 2: Build Docker images
  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build & Push Symfony image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: .devcontainer/Dockerfile.apache.prod
          push: ${{ github.ref == 'refs/heads/main' }}
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/symfony:latest
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/symfony:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/symfony:buildcache,mode=max

      - name: Build & Push Frontend image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: .devcontainer/Dockerfile.spa.prod
          push: ${{ github.ref == 'refs/heads/main' }}
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/frontend:latest

  # Step 3: Deploy
  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to VPS via SSH
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /opt/myapp
            docker-compose pull
            docker-compose up -d

      # Alternative: Deploy to Jelastic
      - name: Deploy to Jelastic
        run: |
          curl -X POST https://api.jelastic.com/1.0/utils/command/exec \
            -d "token=${{ secrets.JELASTIC_TOKEN }}" \
            -d "appid=${{ secrets.JELASTIC_APPID }}" \
            -d "cmd=cd /opt && docker-compose pull && docker-compose up -d"

      # Alternative: Deploy to Heroku (frontend only)
      - name: Deploy Frontend to Heroku
        uses: akhileshns/heroku-deploy@v3.13.15
        with:
          heroku_api_key: ${{ secrets.HEROKU_API_KEY }}
          heroku_app_name: "your-app-frontend"
          heroku_email: ${{ secrets.HEROKU_EMAIL }}
          appdir: frontend

  # Step 4: Health check
  health-check:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - name: Check API health
        run: |
          curl -f https://api.yourdomain.com/health || exit 1
```

**GitHub Secrets to add:**

```
VPS_HOST=your.vps.ip
VPS_USER=deploy
VPS_SSH_KEY=<private-key>
JELASTIC_TOKEN=<token>
JELASTIC_APPID=<app-id>
HEROKU_API_KEY=<key>
HEROKU_EMAIL=email@example.com
```

---

## 5. Alternative Frontend/Backend Frameworks (Quick Reference)

> **Note:** The officially supported frontend frameworks are **Vite (SPA)** and **Next.js (SSR)**. The frameworks below work in development out of the box, but require Dockerfile adaptation for production. See [Framework Adaptation Guide](framework-adaptation.md).

### Frontend Alternatives

| Framework     | Builder | Dev Port | Notes                              |
| ------------- | ------- | -------- | ---------------------------------- |
| **Nuxt**      | vite    | 3000     | Vue-based, SSR/SSG                 |
| **Astro**     | vite    | 4321     | Static-first, integrates with APIs |
| **SvelteKit** | vite    | 5173     | Full-stack capable                 |
| **Remix**     | esbuild | 3000     | React-based, server-side routing   |

**Adaptation for production:** See [Framework Adaptation Guide](framework-adaptation.md) for step-by-step Dockerfile modifications.

### Backend Alternatives

| Framework             | Language | Port | Dockerfile base      |
| --------------------- | -------- | ---- | -------------------- |
| **Laravel**           | PHP      | 8000 | `php:8.3-apache`     |
| **Django**            | Python   | 8000 | `python:3.12`        |
| **Go (Gin)**          | Go       | 8000 | `golang:1.22-alpine` |
| **Node.js (Express)** | JS       | 8000 | `node:22-alpine`     |

---

## 6. Troubleshooting Common Issues

### Image size too large

- Use multi-stage builds (already done ✓)
- Remove unnecessary packages from apt-get
- Use Alpine Linux instead of Debian

### Slow builds

- Cache dependencies layer separately
- Use BuildKit: `DOCKER_BUILDKIT=1 docker build`

### Database connection errors in prod

- Verify DATABASE_URL environment variable
- Check docker network: containers must be on same network
- Test: `docker-compose exec prod php -r "var_dump(getenv('DATABASE_URL'));"`

### SSL certificate issues

- Use Let's Encrypt for real domains
- For development: Use self-signed certs (see [Security docs](security.md))
- Verify HSTS headers are set correctly

---

## Resources

- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Kubernetes Deploy Apps](https://kubernetes.io/docs/tasks/run-application/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Jelastic Documentation](https://docs.jelastic.com/)
- [Symfony Deployment](https://symfony.com/doc/current/deployment.html)
