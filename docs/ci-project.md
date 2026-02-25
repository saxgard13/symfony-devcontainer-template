# Project CI Workflows

This guide covers how to set up GitHub Actions workflows for your **backend (Symfony) and frontend** depending on your repository structure.

---

## What should your CI check?

| Type | Backend (Symfony) | Frontend (Node) |
|---|---|---|
| **Build** | `composer install` | `npm ci` + `npm run build` |
| **Lint** | PHP-CS-Fixer | ESLint |
| **Static analysis** | PHPStan / Psalm | TypeScript (`tsc --noEmit`) |
| **Unit tests** | PHPUnit | Jest / Vitest |
| **Integration tests** | PHPUnit + real DB (`services:`) | API mocking (MSW) |
| **E2E** *(optional)* | WebTestCase (Symfony HTTP client) | Cypress / Playwright |
| **Dependency audit** | `composer audit` | `npm audit` |
| **SAST** | SonarCloud / RIPS | SonarCloud |

> Start with **Build + Lint + Static analysis + Unit tests** — these are fast and catch most regressions. Add integration, E2E and security tools progressively.

**When is E2E critical?** For any serious API + React project, include at least one E2E scenario covering your most critical flow (login, checkout, payment). E2E is "optional" only in the sense that it's not required to start — but for a public-facing app it should be part of your CI before going to production. For a simple internal CRUD app, WebTestCase + unit tests are usually sufficient.

- Backend E2E: [Symfony WebTestCase](https://symfony.com/doc/current/testing.html#functional-tests)
- Frontend E2E: [Cypress](https://docs.cypress.io) · [Playwright](https://playwright.dev)

---

## Security tooling

Security should be treated as a first-class concern in CI, not an afterthought.

### Backend

| Tool | Purpose | How to run |
|---|---|---|
| `composer audit` | Checks `composer.lock` against known CVEs (advisories database) | `composer audit` |
| **local-php-security-checker** | Same as above, faster, no Composer required | `local-php-security-checker` binary |
| **PHPStan** | Static analysis — catches type errors, null dereferences, unreachable code | `vendor/bin/phpstan analyse src/` |
| **PHPStan extensions** | Symfony-aware rules (`phpstan-symfony`), Doctrine (`phpstan-doctrine`), strict rules (`phpstan-strict-rules`) — surface framework-specific bugs and unsafe patterns | add to `phpstan.neon` |
| **Psalm** | Alternative/complement to PHPStan — stronger taint analysis for detecting injection vulnerabilities (SQL, XSS, command injection) | `vendor/bin/psalm` |
| **SonarCloud** | SAST platform — detects security hotspots, code smells, duplications; integrates with GitHub PRs | `sonarcloud-github-action` |
| **RIPS / Snyk Code** | Deep PHP SAST — detects injection flaws, path traversal, deserialization vulnerabilities; commercial but free tier available | external CI action |

**Recommended minimum:** `composer audit` + PHPStan level 6+ with `phpstan-symfony` + Psalm taint analysis.

### Frontend

| Tool | Purpose | How to run |
|---|---|---|
| `npm audit` | Checks `package-lock.json` against known CVEs | `npm audit --audit-level=high` |
| **TypeScript strict mode** | Eliminates implicit `any`, unsafe casts — reduces runtime errors | `"strict": true` in `tsconfig.json` |
| **ESLint security plugins** | `eslint-plugin-security`, `eslint-plugin-no-unsanitized` — detect XSS patterns, `eval`, unsafe `innerHTML` | add to `.eslintrc` |
| **SonarCloud** | Same as backend — detects XSS hotspots, hardcoded secrets, insecure patterns in JS/TS | `sonarcloud-github-action` |

**Recommended minimum:** `npm audit` + TypeScript strict + `eslint-plugin-security`.

### SonarCloud setup

SonarCloud is free for public repositories. Add a single step to any workflow:

```yaml
- name: SonarCloud Scan
  uses: SonarSource/sonarcloud-github-action@master
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

Create a `sonar-project.properties` at the root:

```properties
sonar.projectKey=my-org_my-repo
sonar.organization=my-org
sonar.sources=backend/src,frontend/src
sonar.exclusions=**/vendor/**,**/node_modules/**
```

> Add `SONAR_TOKEN` in your repo's GitHub Secrets (generated from sonarcloud.io).

### Complete security workflow

A dedicated `security.yml` that **fails the PR** on any critical vulnerability:

```yaml
name: Security

on:
  push:
    branches: [main]
    paths: ['backend/**', 'frontend/**']  # monorepo — remove for multirepo
  pull_request:
    branches: [main]
    paths: ['backend/**', 'frontend/**']
  schedule:
    - cron: '0 6 * * 1'  # every Monday at 6am UTC

jobs:
  backend-audit:
    name: Backend dependency audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          tools: composer

      - run: cd backend && composer install --no-interaction --no-dev

      - name: Composer audit (fail on any severity)
        run: cd backend && composer audit --no-dev

  frontend-audit:
    name: Frontend dependency audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - run: cd frontend && npm ci

      - name: npm audit (fail on high/critical only)
        run: cd frontend && npm audit --audit-level=high

  sonarcloud:
    name: SonarCloud SAST
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # required for SonarCloud blame analysis

      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

> The three jobs run in parallel. If any fails, the PR is blocked. The `schedule` ensures weekly scans even without code changes (new CVEs are published daily).

---

## Secrets management

**Never commit secrets.** Use the following conventions:

| File | Committed | Contains |
|---|---|---|
| `.env` | Yes | Default values, structure — no real secrets |
| `.env.local` | No (gitignored) | Local overrides with real credentials |
| `.env.test.local` | No (gitignored) | Test environment overrides |
| `.env.prod.local` | No (gitignored) | Production secrets (if managed locally) |

In CI/CD, inject secrets via **GitHub Secrets** (Settings → Secrets and variables → Actions), then reference them in workflows:

```yaml
env:
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
  APP_SECRET: ${{ secrets.APP_SECRET }}
```

Ensure `.env.local` and `.env.*.local` are in `.gitignore` (Symfony does this by default). Never use real credentials in `.env` — only safe placeholder values.

---

## Repository structures

### Monorepo

Backend and frontend live in the **same repository**:

```
my-repo/
├── backend/        # Symfony
├── frontend/       # React, Next.js, etc.
├── .devcontainer/
└── .github/
    └── workflows/
        ├── ci-backend.yml
        ├── ci-frontend.yml
        └── ...
```

Since everything lives in the same repo, use `paths` filters to scope each workflow to its directory. Without them, every workflow would run on every push — including a backend-only change triggering the frontend build.

```yaml
# ci-backend.yml — only runs when backend/ changes
on:
  push:
    branches: [main]
    paths: ['backend/**']
  pull_request:
    branches: [main]
    paths: ['backend/**']

# ci-frontend.yml — only runs when frontend/ changes
on:
  push:
    branches: [main]
    paths: ['frontend/**']
  pull_request:
    branches: [main]
    paths: ['frontend/**']
```

### Multirepo

Backend and frontend are **separate Git repositories**, each with their own GitHub repo and `git init`:

```
my-org/backend/       # git init → github.com/my-org/backend
├── src/
├── composer.json
└── .github/workflows/
    ├── quality.yml
    └── tests.yml

my-org/frontend/      # git init → github.com/my-org/frontend
├── src/
├── package.json
└── .github/workflows/
    ├── quality.yml
    └── build.yml

my-org/devcontainer/  # git init → github.com/my-org/devcontainer (this template)
├── .devcontainer/
└── .github/workflows/
    ├── ci-devcontainer.yml
    ├── ci-compose.yml
    └── ci-prod-images.yml
```

No `paths` filtering needed — each repo only contains its own code.

---

## Backend workflows (Symfony)

### Quality checks

```yaml
name: Backend Quality

on:
  push:
    branches: [main]
    paths: ['backend/**']        # monorepo only — remove for multirepo
  pull_request:
    branches: [main]
    paths: ['backend/**']        # monorepo only — remove for multirepo

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          tools: composer

      - name: Cache Composer
        uses: actions/cache@v4
        with:
          path: backend/vendor
          key: composer-${{ hashFiles('backend/composer.lock') }}

      - run: cd backend && composer install --no-interaction

      - name: PHP-CS-Fixer
        run: cd backend && vendor/bin/php-cs-fixer fix src/ --dry-run --diff

      - name: PHPStan
        run: cd backend && vendor/bin/phpstan analyse src/
```

### Tests

```yaml
name: Backend Tests

on:
  push:
    branches: [main]
    paths: ['backend/**']
  pull_request:
    branches: [main]
    paths: ['backend/**']

jobs:
  tests:
    runs-on: ubuntu-latest

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: symfony_test
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3
        ports:
          - 3306:3306

    steps:
      - uses: actions/checkout@v4

      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          tools: composer
          extensions: pdo_mysql

      - name: Cache Composer
        uses: actions/cache@v4
        with:
          path: backend/vendor
          key: composer-${{ hashFiles('backend/composer.lock') }}

      - run: cd backend && composer install --no-interaction

      - name: Run migrations
        run: cd backend && php bin/console doctrine:migrations:migrate --env=test --no-interaction
        env:
          DATABASE_URL: mysql://root:root@127.0.0.1:3306/symfony_test

      - name: Run tests
        run: cd backend && php bin/phpunit
        env:
          DATABASE_URL: mysql://root:root@127.0.0.1:3306/symfony_test
```

> **PostgreSQL variant:** replace the `mysql` service with `image: postgres:16`, set `POSTGRES_PASSWORD`, `POSTGRES_DB`, and adjust `DATABASE_URL` to `postgresql://...`.

---

## Frontend workflows

### Quality checks

```yaml
name: Frontend Quality

on:
  push:
    branches: [main]
    paths: ['frontend/**']       # monorepo only — remove for multirepo
  pull_request:
    branches: [main]
    paths: ['frontend/**']       # monorepo only — remove for multirepo

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - run: cd frontend && npm ci

      - name: ESLint
        run: cd frontend && npm run lint

      - name: TypeScript
        run: cd frontend && npm run type-check
```

### Build

```yaml
name: Frontend Build

on:
  push:
    branches: [main]
    paths: ['frontend/**']
  pull_request:
    branches: [main]
    paths: ['frontend/**']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - run: cd frontend && npm ci
      - run: cd frontend && npm run build
```

---

## Monorepo: recommended file layout

```
.github/workflows/
├── ci-devcontainer.yml     # Template workflows (already included)
├── ci-compose.yml
├── ci-prod-images.yml
├── backend-quality.yml     # Your project workflows
├── backend-tests.yml
├── frontend-quality.yml
└── frontend-build.yml
```

Each workflow uses `paths` to scope itself. A push to `backend/src/` will only trigger `backend-*.yml`, not `frontend-*.yml`.

---

## Multirepo: recommended file layout

Each repo has its own `.github/workflows/` without `paths` filtering:

```
# my-org/backend repo
.github/workflows/
├── quality.yml
└── tests.yml

# my-org/frontend repo
.github/workflows/
├── quality.yml
└── build.yml
```

The devcontainer template lives in its own repo and keeps the 3 `ci-*.yml` workflows as-is.

---

## Deployment

Deployment is highly dependent on your hosting provider (VPS, Kubernetes, PaaS, etc.) and is out of scope for this template. Common approaches:

- **Manual trigger** (`workflow_dispatch`) with SSH + `docker compose pull && docker compose up -d`
- **CD platform** (Render, Railway, Fly.io) that detects pushes automatically
- **GitHub Environments** with approval gates for production

See your hosting provider's documentation for the recommended GitHub Actions integration.
