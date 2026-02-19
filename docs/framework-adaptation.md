# Framework Adaptation Guide

This guide explains how to adapt the production Docker setup for Node.js frameworks other than Next.js.

> **Development:** Any Node.js framework works out of the box in the dev container. VS Code auto-detects and forwards ports. No configuration needed.
>
> **Production:** `Dockerfile.node.prod` is pre-configured for **Next.js standalone mode**. For other SSR frameworks, follow the steps below.

---

## Prerequisites

Read `Dockerfile.node.prod` before starting. The 3 stages are:
1. **deps** — installs npm/yarn/pnpm dependencies
2. **builder** — runs `npm run build`
3. **runner** — lean image that runs the app

Stages 1 and 2 are framework-agnostic. Only **stage 3 (runner)** needs adaptation.

---

## Adapting for Nuxt

**What changes in `Dockerfile.node.prod`:**

### 1. Remove Next.js telemetry env vars (builder + runner stages)

```dockerfile
# Remove this line from both builder and runner stages:
ENV NEXT_TELEMETRY_DISABLED=1
```

### 2. Fix the builder stage mkdir

```dockerfile
# Replace:
RUN ... && mkdir -p public .next/standalone .next/static

# With:
RUN ... && mkdir -p .output
```

### 3. Replace the COPY statements in the runner stage

```dockerfile
# Remove (Next.js specific):
COPY --from=builder --chown=appuser:nodejs /app/public ./public
COPY --from=builder --chown=appuser:nodejs /app/.next/standalone ./
COPY --from=builder --chown=appuser:nodejs /app/.next/static ./.next/static

# Add (Nuxt):
COPY --from=builder --chown=appuser:nodejs /app/.output ./
```

### 4. Change the HOSTNAME env var

```dockerfile
# Replace:
ENV HOSTNAME="0.0.0.0"

# With:
ENV HOST=0.0.0.0
```

### 5. Change the CMD

```dockerfile
# Replace:
CMD ["node", "server.js"]

# With:
CMD ["node", ".output/server/index.mjs"]
```

**Port:** Nuxt uses **3000** by default — no change needed to `EXPOSE` or `ENV PORT`.

> **Save as:** Copy `Dockerfile.node.prod` to `Dockerfile.nuxt.prod` and update `docker-compose.node.prod.yml` to reference the new file.

---

## Adapting for Astro (SSR mode)

Astro in SSR mode requires a Node.js adapter.

### 1. Add the Node adapter to your Astro project

```bash
npx astro add node
```

This configures `astro.config.mjs` to output a Node.js server.

### 2. Adapt `Dockerfile.node.prod`

**Builder stage:**

```dockerfile
# Replace:
ENV NEXT_TELEMETRY_DISABLED=1

# With: (remove it entirely, not needed for Astro)
```

```dockerfile
# Replace:
RUN ... && mkdir -p public .next/standalone .next/static

# With:
RUN ... && mkdir -p dist
```

**Runner stage:**

```dockerfile
# Replace the COPY statements:
COPY --from=builder --chown=appuser:nodejs /app/dist ./dist
COPY --from=builder --chown=appuser:nodejs /app/node_modules ./node_modules

# Change EXPOSE and ENV PORT:
EXPOSE 4321
ENV PORT=4321
ENV HOST=0.0.0.0

# Change CMD:
CMD ["node", "./dist/server/entry.mjs"]
```

> **Save as:** `Dockerfile.astro.prod`

---

## Generic Pattern (Any SSR Framework)

1. **Identify your framework's build output directory** (e.g., `.output/`, `dist/`, `build/`)
2. **Copy that directory** in the runner stage
3. **Set the correct port** via `EXPOSE` and `ENV PORT`
4. **Set the start command** (e.g., `node server.js`, `node .output/server/index.mjs`)

**Quick reference:**

| Framework    | Build output             | Default port | Start command                        |
| ------------ | ------------------------ | ------------ | ------------------------------------ |
| **Next.js**  | `.next/standalone/`      | 3000         | `node server.js`                     |
| **Nuxt**     | `.output/`               | 3000         | `node .output/server/index.mjs`      |
| **Astro**    | `dist/`                  | 4321         | `node ./dist/server/entry.mjs`       |
| **SvelteKit**| `build/`                 | 3000         | `node build/index.js`                |
| **Remix**    | `build/`                 | 3000         | `node build/server/index.js`         |

---

## Updating docker-compose.node.prod.yml

After creating your new Dockerfile, update the compose file to reference it:

```yaml
services:
  app:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile.nuxt.prod  # ← change here
```

Also update `FRONTEND_LOCALHOST_PORT` in `.devcontainer/.env` if your framework uses a different port:

```env
FRONTEND_LOCALHOST_PORT=4321  # For Astro
```
