# Framework Adaptation Guide

This guide covers two topics:

1. **Development setup** — configuring the devcontainer for a framework other than Vite (the default)
2. **Production Dockerfile** — adapting `Dockerfile.node.prod` for frameworks other than Next.js

---

## Part 1 — Development Setup

The devcontainer works out of the box with any Node.js framework. However, a few values are pre-configured for **Vite (port 5173)** by default. If you switch to another framework, update these two files.

### Example: switching from Vite to Next.js

**1. Update `FRONTEND_LOCALHOST_PORT` in `.devcontainer/.env`:**

```env
# Default (Vite):
FRONTEND_LOCALHOST_PORT=5173

# Next.js:
FRONTEND_LOCALHOST_PORT=3000
```

This value controls which port is exposed by Docker Compose for the frontend.

**2. Add your framework's port to `forwardPorts` in `.devcontainer/devcontainer.json`:**

```json
"forwardPorts": [8000, 5173, 3000, 4321]
```

Add the port if it's not already listed. This tells VS Code which ports to forward from the container to your host machine.

**3. Start the dev server with `--host` (required inside Docker):**

```bash
# Vite (default):
npm run dev -- --host

# Next.js:
npm run dev -- -H 0.0.0.0

# Other frameworks: pass the equivalent --host 0.0.0.0 flag
```

Without this, the dev server binds to `127.0.0.1` only and is unreachable from the host.

**4. (Optional) HTTPS via Caddy:**

If you use the Caddy reverse proxy, add a block in `.devcontainer/config/caddy/Caddyfile` for your framework's port and map it in `docker-compose.reverseproxy.yml`. See [HTTPS Guide](https.md) for details.

### Port reference

| Framework    | Default dev port |
| ------------ | ---------------- |
| **Vite**     | 5173             |
| **Next.js**  | 3000             |
| **Nuxt**     | 3000             |
| **Astro**    | 4321             |
| **SvelteKit**| 5173             |
| **Remix**    | 3000             |

> After changing `devcontainer.json`, rebuild the container (`Ctrl+Shift+P` → Rebuild Container) for the changes to take effect.

---

## Part 2 — Production Dockerfile

`Dockerfile.node.prod` is pre-configured for **Next.js standalone mode**. For other SSR frameworks, adapt the runner stage as described below.

### Prerequisites

Read `Dockerfile.node.prod` before starting. The 3 stages are:
1. **deps** — installs npm/yarn/pnpm dependencies
2. **builder** — runs `npm run build`
3. **runner** — lean image that runs the app

Stages 1 and 2 are framework-agnostic. Only **stage 3 (runner)** needs adaptation.

---

### Adapting for Nuxt

**What changes in `Dockerfile.node.prod`:**

#### 1. Remove Next.js telemetry env vars (builder + runner stages)

```dockerfile
# Remove this line from both builder and runner stages:
ENV NEXT_TELEMETRY_DISABLED=1
```

#### 2. Fix the builder stage mkdir

```dockerfile
# Replace:
RUN ... && mkdir -p public .next/standalone .next/static

# With:
RUN ... && mkdir -p .output
```

#### 3. Replace the COPY statements in the runner stage

```dockerfile
# Remove (Next.js specific):
COPY --from=builder --chown=appuser:nodejs /app/public ./public
COPY --from=builder --chown=appuser:nodejs /app/.next/standalone ./
COPY --from=builder --chown=appuser:nodejs /app/.next/static ./.next/static

# Add (Nuxt):
COPY --from=builder --chown=appuser:nodejs /app/.output ./
```

#### 4. Change the HOSTNAME env var

```dockerfile
# Replace:
ENV HOSTNAME="0.0.0.0"

# With:
ENV HOST=0.0.0.0
```

#### 5. Change the CMD

```dockerfile
# Replace:
CMD ["node", "server.js"]

# With:
CMD ["node", ".output/server/index.mjs"]
```

**Port:** Nuxt uses **3000** by default — no change needed to `EXPOSE` or `ENV PORT`.

> **Save as:** Copy `Dockerfile.node.prod` to `Dockerfile.nuxt.prod` and update `docker-compose.node.prod.yml` to reference the new file.

---

### Adapting for Astro (SSR mode)

Astro in SSR mode requires a Node.js adapter.

#### 1. Add the Node adapter to your Astro project

```bash
npx astro add node
```

This configures `astro.config.mjs` to output a Node.js server.

#### 2. Adapt `Dockerfile.node.prod`

**Builder stage:**

```dockerfile
# Remove (not needed for Astro):
ENV NEXT_TELEMETRY_DISABLED=1

# Replace:
RUN ... && mkdir -p public .next/standalone .next/static

# With:
RUN ... && mkdir -p dist
```

**Runner stage:**

```dockerfile
# Remove (Next.js specific):
COPY --from=builder --chown=appuser:nodejs /app/public ./public
COPY --from=builder --chown=appuser:nodejs /app/.next/standalone ./
COPY --from=builder --chown=appuser:nodejs /app/.next/static ./.next/static
ENV HOSTNAME="0.0.0.0"

# Add (Astro):
COPY --from=builder --chown=appuser:nodejs /app/dist ./dist
COPY --from=builder --chown=appuser:nodejs /app/node_modules ./node_modules
ENV HOST=0.0.0.0

# Replace EXPOSE and ENV PORT:
EXPOSE 4321
ENV PORT=4321

# Replace CMD:
CMD ["node", "./dist/server/entry.mjs"]
```

> **Save as:** `Dockerfile.astro.prod`

---

### Generic Pattern (Any SSR Framework)

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

### Updating docker-compose.node.prod.yml

After creating your new Dockerfile, update the compose file to reference it:

```yaml
services:
  app:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile.nuxt.prod  # ← change here
```

Also update `FRONTEND_LOCALHOST_PORT` in `.devcontainer/.env` to match your framework's production port:

```env
FRONTEND_LOCALHOST_PORT=4321  # Astro
FRONTEND_LOCALHOST_PORT=3000  # Nuxt, SvelteKit, Remix
```
