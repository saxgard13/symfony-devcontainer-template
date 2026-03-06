# HTTPS in Development

This guide explains how to set up HTTPS for local development using a Caddy reverse proxy, covering all supported architectural setups.

---

## Overview

A lightweight **Caddy container** acts as an optional add-on. Caddy terminates TLS and forwards plain HTTP to the internal services.

```
Browser → HTTPS → Caddy → HTTP → Symfony CLI / Vite / Next.js
```

**Why Caddy:**
- Generates and manages its own CA automatically — no manual certificate setup
- Works with PHP-CLI (`symfony serve`) via a simple `reverse_proxy` directive — no FastCGI needed
- Fully optional: add or remove one line in `devcontainer.json`
- No IDE-specific configuration required

## Services (with HTTPS enabled)

| Service | HTTPS URL | HTTP fallback | Notes |
|---|---|---|---|
| **Symfony backend** | https://localhost:8443 | http://localhost:8000 | Via Caddy |
| **Vite SPA frontend** | https://localhost:5443 | http://localhost:5173 | Via Caddy |
| **Next.js** | https://localhost:3443 | http://localhost:3000 | Via Caddy |
| **Adminer** | — | http://localhost:8080 | Not proxied by Caddy |
| **Mailpit** | — | http://localhost:8025 | Not proxied by Caddy |

> Adminer and Mailpit are internal dev tools — no HTTPS needed for them.

---

## When do you need HTTPS in development?

HTTPS is optional for basic development, but required as soon as you work on any of the following:

| Scenario | Why HTTPS is required |
|---|---|
| **`Secure` cookies** | Browsers only send cookies with `Secure` flag over HTTPS — authentication and sessions won't work correctly without it |
| **`SameSite=None` cookies** | Required for cross-site requests (e.g. embedded widgets, iframes) — only accepted over HTTPS |
| **OAuth / external providers** | Most OAuth providers (Google, GitHub…) require a valid HTTPS callback URL, even in development |
| **External APIs blocked on HTTP** | Some third-party APIs reject requests originating from non-HTTPS pages |
| **Service Workers** | The Service Worker API is only available on HTTPS origins (or `localhost` without a proxy) |
| **Mixed content** | A page served over HTTPS cannot load resources over HTTP — JS, images, fonts must also use HTTPS |
| **Strict CSP / security headers** | Headers like `Strict-Transport-Security` or `upgrade-insecure-requests` require an HTTPS context to behave correctly |

> If you only do basic data fetching without auth or cookies, plain HTTP is sufficient.

---

## Supported architectures

### Full Symfony

Symfony handles everything (Twig, API, assets). Only one service needs HTTPS.

```
Browser → HTTPS Caddy:8443 → HTTP Symfony:8000
```

**Environment:**
```dotenv
APP_URL=https://localhost:8443
```

---

### Symfony + SPA frontend (Vite / React / Vue)

Vite serves the SPA. All API calls are made **client-side** (from the browser), so the browser handles HTTPS directly — no server-side fetch issues.

```
Browser → HTTPS Caddy:8443 → HTTP Symfony:8000
Browser → HTTPS Caddy:5443 → HTTP Vite:5173
```

**Environment:**
```dotenv
# Symfony
APP_URL=https://localhost:8443
CORS_ALLOW_ORIGIN=https://localhost:5443

# Frontend (client-side only, browser handles HTTPS)
VITE_API_URL=https://localhost:8443
```

> `CORS_ALLOW_ORIGIN` must match the browser's actual origin (`https://localhost:5443`), not the internal Vite port. Without this, Symfony will reject cross-origin requests.

---

### Symfony + Next.js SSR / ISR

This is the most complex scenario. Next.js makes **server-side fetches** to Symfony (SSR/ISR). With Caddy, Next.js calls Symfony via **plain HTTP internally** — eliminating all Node.js CA trust issues.

```
Browser → HTTPS Caddy:3443 → HTTP Next.js:3000
Next.js SSR → HTTP localhost:8000 → Symfony (no TLS, no CA issues)
Browser → HTTPS Caddy:8443 → HTTP Symfony:8000
```

**Environment (Next.js `.env.local`):**
```dotenv
# Server-side fetches (Next.js → Symfony, plain HTTP internally — no TLS, no CA to trust)
API_URL=http://localhost:8000

# Client-side fetches (browser → Caddy → Symfony, HTTPS)
NEXT_PUBLIC_API_URL=https://localhost:8443
```

**Symfony `project/backend/.env.local`** _(only if using `clientFetch` — browser → Caddy → Symfony directly)_:
```dotenv
# Browser origin is https://localhost:3443 (Next.js via Caddy)
CORS_ALLOW_ORIGIN=https://localhost:3443
```

> **CORS only applies to browser-initiated requests.** Server-side fetches (`serverFetch`, Server Components, `getServerSideProps`) run inside the Node.js container — they have no `Origin` header and bypass CORS entirely. `CORS_ALLOW_ORIGIN` only matters if the browser makes a direct cross-origin call to Symfony via `clientFetch`.

> Key advantage: no `--experimental-https`, no `NODE_EXTRA_CA_CERTS`, no IDE-specific `remoteEnv` needed. Next.js runs on plain HTTP internally, Caddy handles TLS for the browser.

#### Organizing fetches in Next.js

The distinction is not GET vs POST — it is **where** the fetch runs:

| Context | Variable | Path | Use for |
|---|---|---|---|
| Server Component / SSR | `API_URL` | HTTP direct → Symfony | Public data for initial render |
| Client Component (`"use client"`) | `NEXT_PUBLIC_API_URL` | HTTPS → Caddy → Symfony | Auth, mutations, user-session operations |

```typescript
// lib/api.ts
const serverBase = process.env.API_URL              // http://localhost:8000
const clientBase = process.env.NEXT_PUBLIC_API_URL  // https://localhost:8443

// Server Components / SSR — public data fetching
export async function serverFetch(path: string, options?: RequestInit) {
  return fetch(`${serverBase}${path}`, options)
}

// Client Components ("use client") — auth, mutations, session
export async function clientFetch(path: string, options?: RequestInit) {
  return fetch(`${clientBase}${path}`, options)
}
```

**Rule of thumb:** if the request involves the user's session or sets cookies (login, registration, any authenticated mutation) → `clientFetch` → goes through Caddy → Symfony correctly sets `Secure` cookies.

`serverFetch` bypasses Caddy entirely — Symfony receives plain HTTP and will not set `Secure` cookies on those responses. Use it only for public read-only data.

---

### Full Next.js (no Symfony)

Next.js handles everything — pages, API routes, data access. Symfony is not used. Caddy only proxies Next.js.

```
Browser → HTTPS Caddy:3443 → HTTP Next.js:3000
```

No specific environment variables needed for Caddy: the browser loads pages and calls API routes on the same origin (`https://localhost:3443`), so relative URLs (`/api/users`) work as-is.

You can comment out the Symfony and Vite blocks in the Caddyfile if they are not needed:

```
# https://localhost:8443 {
#     reverse_proxy dev:8000
# }
# https://localhost:5443 {
#     reverse_proxy dev:5173
# }

https://localhost:3443 {
    reverse_proxy dev:3000
}
```

---

## Setup

### 1. The Caddy docker-compose file

Already provided at `.devcontainer/docker-compose.reverseproxy.yml`:

```yaml
services:
  caddy:
    image: caddy:alpine
    ports:
      - "8443:8443"
      - "5443:5443"
      - "3443:3443"
    volumes:
      - ./config/caddy/Caddyfile:/etc/caddy/Caddyfile
      - ./config/caddy/entrypoint.sh:/entrypoint.sh
      - ./config/caddy/export:/export
      - caddy_data:/data
    entrypoint: ["/bin/sh", "/entrypoint.sh"]
    depends_on:
      dev:
        condition: service_started
    networks:
      - app-network

volumes:
  caddy_data:
```

**Port mapping note:** Caddy listens on the port specified in the Caddyfile site address (e.g. `https://localhost:8443` → port 8443 inside the container). The host mapping must match: `8443:8443`, not `8443:443`.

**Volume note:** Private keys stay in the named Docker volume `caddy_data` (never on the host). Only `root.crt` (the public CA certificate) is exported to the bind-mounted `export/` directory via the entrypoint script.

### 2. The Caddyfile

Already provided at `.devcontainer/config/caddy/Caddyfile`. All three blocks are enabled by default — comment out any blocks you don't need:

```
# Symfony backend (all setups)
# IMPORTANT: Symfony must run on plain HTTP — use: symfony serve --no-tls
https://localhost:8443 {
    reverse_proxy dev:8000
}

# Vite SPA frontend
https://localhost:5443 {
    reverse_proxy dev:5173
}

# Next.js SSR/ISR
# Next.js runs on plain HTTP internally, Caddy handles TLS for the browser.
# SSR fetches to Symfony use http://localhost:8000 (no TLS, no CA issues).
https://localhost:3443 {
    reverse_proxy dev:3000
}
```

> If a backend isn't running (e.g. no Next.js server), Caddy returns `502 Bad Gateway` for that port only — other proxied services are unaffected.

> `dev` refers to the main devcontainer service name defined in `docker-compose.dev.yml`.

> **Important:** Caddy proxies via plain HTTP to the internal services. Symfony must therefore run without TLS: `symfony serve --no-tls`. If Symfony runs in HTTPS mode (default when the Symfony CLI CA is installed), Caddy will fail to connect.

#### Other frameworks (Nuxt, Remix, Astro, etc.)

The Caddyfile only covers Vite (5173) and Next.js (3000) by default. For any other framework, add a block with the port it uses:

```
https://localhost:4443 {
    reverse_proxy dev:4321
}
```

Also add the matching port mapping in `docker-compose.reverseproxy.yml`:

```yaml
ports:
  - "4443:4443"
```

Then reload: `docker exec backend_devcontainer-caddy-1 caddy reload --config /etc/caddy/Caddyfile`

> Make sure the framework dev server binds to `0.0.0.0` (not `127.0.0.1`) — see step 5.

#### Modifying the Caddyfile after startup

Caddy does not watch the Caddyfile for changes. After any modification, reload the config without restarting the container:

```bash
docker exec backend_devcontainer-caddy-1 caddy reload --config /etc/caddy/Caddyfile
```

### 3. Enable it in devcontainer.json

`docker-compose.reverseproxy.yml` is already included by default:

```json
"dockerComposeFile": [
    "docker-compose.dev.yml",
    "docker-compose.mysql.yml",
    "docker-compose.redis.yml",
    "docker-compose.mailpit.yml",
    "docker-compose.reverseproxy.yml"
]
```

Remove this line and rebuild to disable HTTPS entirely.

---

## Disabling HTTPS (reverting to plain HTTP)

**1. Remove Caddy from `devcontainer.json`** (optional — Caddy is lightweight and harmless when unused, but removing it keeps things explicit):

```json
"dockerComposeFile": [
    "docker-compose.dev.yml",
    "docker-compose.mysql.yml",
    "docker-compose.redis.yml",
    "docker-compose.mailpit.yml"
    // remove docker-compose.reverseproxy.yml
]
```

**2. Rebuild the devcontainer** (`Ctrl+Shift+P` → Rebuild Container).

**3. Update your frontend `.env.local`** to point back to plain HTTP:

```dotenv
# Next.js SSR — client-side fetches go directly to Symfony (no Caddy)
NEXT_PUBLIC_API_URL=http://localhost:8000

# Vite SPA
VITE_API_URL=http://localhost:8000
```

**Also update `CORS_ALLOW_ORIGIN`** in `project/backend/.env.local` to match the plain HTTP origin:

```dotenv
# Vite SPA
CORS_ALLOW_ORIGIN=http://localhost:5173

# Next.js
# CORS_ALLOW_ORIGIN=http://localhost:3000
```

**4. Start services normally** (no flags needed):

```bash
# Symfony
symfony server:start --no-tls --listen-ip=0.0.0.0 --port=8000

# Next.js
npm run dev
```

> `TRUSTED_PROXIES` in `project/backend/.env` can stay as-is — it has no effect when Caddy is not running since no `X-Forwarded-*` headers are sent.

---

### 4. Trust Caddy's CA in your browser

On first startup, Caddy automatically generates its local CA and exports the root certificate to `.devcontainer/config/caddy/export/root.crt` (this directory is gitignored).

Import this file into your browser or OS trust store — this is a one-time operation per machine:

- **Firefox:** `about:preferences#privacy` → Certificates → View Certificates → Authorities → Import → select `root.crt`
- **Chrome / Edge:** `Settings` → Privacy and Security → Security → Manage certificates → Authorities → Import
- **Linux OS trust store:** `sudo cp root.crt /usr/local/share/ca-certificates/caddy-root.crt && sudo update-ca-certificates`

> The `export/` directory is machine-specific and gitignored. Each developer imports their own instance's certificate.

### 5. Start services on all interfaces

By default, `symfony serve` and `next dev` bind to `127.0.0.1` (loopback only), which is **not reachable from the Caddy container**. You must bind to `0.0.0.0`:

**Symfony:**
```bash
symfony server:start --no-tls --listen-ip=0.0.0.0 --port=8000
```

**Next.js:**
```bash
npm run dev -- -H 0.0.0.0
```

> Without `0.0.0.0`, Caddy will get a `Connection refused` and the browser will show `PR_END_OF_FILE_ERROR`.

### 6. Configure Symfony trusted proxies

Already configured in `config/packages/framework.yaml`:

```yaml
framework:
    # Trust reverse proxy headers (Caddy in dev, Nginx LB in prod)
    trusted_proxies: '%env(TRUSTED_PROXIES)%'
    trusted_headers: ['x-forwarded-for', 'x-forwarded-proto', 'x-forwarded-port']
```

And in `.env`:

```dotenv
# REMOTE_ADDR = trust whoever connects directly (Caddy container) — suitable for dev
# In production, replace with your load balancer's fixed IP (e.g. TRUSTED_PROXIES=10.0.0.1)
TRUSTED_PROXIES=REMOTE_ADDR
```

---

## How trusted_proxies works

Reverse proxies forward original request metadata via `X-Forwarded-*` headers. Without `trusted_proxies`, Symfony ignores these headers for security reasons.

| Header | Value | Effect in Symfony |
|---|---|---|
| `X-Forwarded-Proto` | `https` | `$request->isSecure()` returns `true` |
| `X-Forwarded-For` | Client's real IP | `$request->getClientIp()` returns the visitor's IP |
| `X-Forwarded-Port` | `443` | Generated URLs use the correct port |

**What this unlocks:**
- `cookie_secure: auto` → Symfony sets the `Secure` flag on session cookies
- Generated URLs use `https://`
- IP-based rate limiting and logging see the real client IP

---

## Production (Jelastic with Nginx Load Balancer)

On Jelastic, the Nginx load balancer handles SSL termination natively — certificates are managed through the Jelastic control panel (Let's Encrypt built-in). You do not write Nginx SSL configuration yourself.

The LB accepts only HTTPS from the internet and redirects HTTP → HTTPS automatically. Application containers are never directly reachable from outside — HTTP access on internal ports is impossible. There is no equivalent of the dev "bypass via port 3000" problem.

Symfony receives plain HTTP from the LB and uses the same `trusted_proxies` configuration. Only the IP changes — override `TRUSTED_PROXIES` via your platform's environment variables or `.env.local`:

```dotenv
# Production: replace with your Jelastic LB's fixed IP
TRUSTED_PROXIES=10.0.0.1
```

> In production, always specify the actual IP of your load balancer instead of `REMOTE_ADDR`, to prevent clients from forging `X-Forwarded-*` headers.

| Environment | `TRUSTED_PROXIES` value | Reason |
|---|---|---|
| Dev (Caddy) | `REMOTE_ADDR` | Trusts whoever connects directly (Caddy container) |
| Prod (Jelastic Nginx LB) | Fixed LB IP | Prevents header forgery by clients |
