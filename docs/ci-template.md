# CI — DevContainer Template Workflows

This template includes **3 GitHub Actions workflows** that validate the devcontainer configuration and production Docker images automatically on every push and pull request.

All workflow files are located in `.github/workflows/`.

---

## Overview

| Workflow | File | Triggers on |
|---|---|---|
| CI - DevContainer | `ci-devcontainer.yml` | `Dockerfile.dev`, `devcontainer.json`, dev compose files, shell scripts |
| CI - Docker Compose | `ci-compose.yml` | Any `docker-compose*.yml` |
| CI - Production Images | `ci-prod-images.yml` | `Dockerfile.*.prod` |

Each workflow also triggers when **its own file is modified**, and can be run manually via `workflow_dispatch`.

---

## CI - DevContainer

**File:** `.github/workflows/ci-devcontainer.yml`

Runs when the devcontainer configuration changes.

### Jobs

| Job | What it does |
|---|---|
| **Build & Test DevContainer** | Builds the full devcontainer using `devcontainers/ci@v0.3` and runs smoke tests: `php --version`, `composer --version`, `node --version`, `symfony version` |
| **Lint Dockerfile.dev** | Runs Hadolint on `Dockerfile.dev` to enforce Dockerfile best practices |
| **Lint Shell Scripts** | Runs ShellCheck on `init.sh`, `setup.sh`, and `config/caddy/entrypoint.sh` |

### Triggered paths

```
.devcontainer/Dockerfile.dev
.devcontainer/devcontainer.json
.devcontainer/docker-compose.dev.yml
.devcontainer/docker-compose.mysql.yml
.devcontainer/docker-compose.postgre.yml
.devcontainer/docker-compose.redis.yml
.devcontainer/docker-compose.mailpit.yml
.devcontainer/docker-compose.reverseproxy.yml
.devcontainer/*.sh
.devcontainer/config/**
.github/workflows/ci-devcontainer.yml
```

---

## CI - Docker Compose

**File:** `.github/workflows/ci-compose.yml`

Runs when any `docker-compose*.yml` file changes.

### Job

**Validate Docker Compose Files** — Runs `docker compose config --quiet` on every supported stack combination to catch syntax errors and invalid service references.

Combinations validated:

| Stack | Compose files |
|---|---|
| Dev + MySQL | `dev` + `mysql` + `redis` + `mailpit` |
| Dev + PostgreSQL | `dev` + `postgre` + `redis` + `mailpit` |
| Dev + MySQL + Reverseproxy | `dev` + `mysql` + `redis` + `mailpit` + `reverseproxy` |
| Prod (Apache) + MySQL | `prod` + `mysql` + `mailpit` |
| Prod (Apache) + PostgreSQL | `prod` + `postgre` + `mailpit` |
| Prod (Node) + MySQL | `node.prod` + `mysql` + `mailpit` |
| Prod (Node) + PostgreSQL | `node.prod` + `postgre` + `mailpit` |
| Prod (SPA) + MySQL | `frontend.prod` + `mysql` + `mailpit` |
| Prod (SPA) + PostgreSQL | `frontend.prod` + `postgre` + `mailpit` |

> The dev stack always requires a db, redis, and mailpit file — they cannot be validated in isolation.

---

## CI - Production Images

**File:** `.github/workflows/ci-prod-images.yml`

Runs when a production Dockerfile changes.

### Jobs

| Job | What it does |
|---|---|
| **Lint Prod Dockerfiles** | Runs Hadolint on all 3 prod Dockerfiles |
| **Build Apache Production Image** | Builds `Dockerfile.apache.prod` with a minimal stub `composer.json` |
| **Build Node.js Production Image** | Builds `Dockerfile.node.prod` with stub `package.json` / `package-lock.json` |
| **Build SPA Production Image** | Builds `Dockerfile.spa.prod` with stub frontend files |

Builds use GitHub Actions cache (`type=gha`) to speed up repeated runs. Images are never pushed (`push: false`).

### Triggered paths

```
.devcontainer/Dockerfile.apache.prod
.devcontainer/Dockerfile.node.prod
.devcontainer/Dockerfile.spa.prod
.github/workflows/ci-prod-images.yml
```

---

## Path-based triggers

Each workflow only runs when a **relevant file changes**. A push that only touches `docs/` or `backend/src/` will not trigger any of these workflows.

When multiple workflows share a triggered file (e.g. a `docker-compose*.yml` triggers both `ci-compose` and `ci-devcontainer`), they run in parallel — there is no dependency between them.
