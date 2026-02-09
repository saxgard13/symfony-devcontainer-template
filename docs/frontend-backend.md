# Frontend ↔ Backend Communication

This guide explains how to configure communication between Symfony (API) and a frontend framework (React, Vue, Next.js, etc.) inside Docker containers.

> **Important:** Service names, ports, and URLs differ between **development** and **production**. See the comparison below.

## Development vs Production

The template supports different architectures for development and production:

### ⚠️ Key Point: Development is Always the Same

**No matter which rendering strategy (SPA, SSR, or ISR) you choose for production**, your development setup is always the same:

```bash
# Development - same for all projects
docker compose \
  -f .devcontainer/docker-compose.dev.yml \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.redis.yml \
  up
```

This single `dev` container includes everything: PHP, Node.js, frontend dev server, backend server.

**The choice between SPA/SSR/ISR only affects how you deploy to production** (which docker-compose files you use).

### Service Names: Where Do They Come From?

The service names (like `dev`, `prod`, `frontend`, `app`) are **defined in the docker-compose files**. The service name becomes the **internal Docker hostname**:

**Development** (`docker-compose.dev.yml`):
```yaml
services:
  dev:  # ← Service name = internal hostname
    build: ...
    ports:
      - "8000:8000"  # Symfony backend
      - "5173:5173"  # Frontend dev server (Vite)
```
- **From inside the container:** `http://dev:8000` (backend) and `http://dev:5173` (frontend)
- **From browser (localhost):** `http://localhost:8000` and `http://localhost:5173`

---

**Production - SPA** (`docker-compose.frontend.prod.yml`):
```yaml
services:
  frontend:  # ← Service name = "frontend"
    build:
      dockerfile: Dockerfile.spa.prod
    ports:
      - "5173:80"  # Nginx static server
```
- **From another container:** `http://frontend:5173` (Nginx)

---

**Production - SSR/ISR** (`docker-compose.node.prod.yml`):
```yaml
services:
  app:  # ← Service name = "app"
    build:
      dockerfile: Dockerfile.node.prod
    ports:
      - "3000:3000"  # Node.js server with SSR
```
- **From another container:** `http://app:3000` (Node.js)

---

### Service Names Summary

| Environment | Backend Service | Frontend Service | Reasoning |
|-------------|-----------------|------------------|-----------|
| **Dev** | `dev` | `dev` | Single container, both services |
| **Prod (SPA)** | `prod` | `frontend` | Descriptive: backend vs frontend SPA |
| **Prod (SSR)** | `prod` | `app` | Descriptive: backend vs full Node.js app |

**Important:** These names are **arbitrary** - you can rename them in docker-compose files, but you must update CORS and API URLs accordingly.

---

### Development Environment

In development, a single container runs both backend and frontend:

| Component | Service | Port | Notes |
|-----------|---------|------|-------|
| Backend (Symfony) | `dev` | 8000 | PHP + Apache |
| Frontend (Vite/dev server) | `dev` | 5173 | Runs inside same container |
| Database | `db` | 3306 (internal) | MySQL |

**Compose file:** `docker-compose.dev.yml`

### Production Environment (Scenario: Symfony API + SPA)

In production, backend and frontend are separate services:

| Component | Service | Image | Port | Notes |
|-----------|---------|-------|------|-------|
| Backend (Symfony) | `prod` | `Dockerfile.apache.prod` | 8000 | Apache + PHP |
| Frontend (SPA) | `frontend` | `Dockerfile.spa.prod` | 5173 | Nginx serving static files |
| Database | `db` | MySQL image | 3306 (internal) | MySQL |

**Compose files:**
- `docker-compose.prod.yml` (backend)
- `docker-compose.frontend.prod.yml` (frontend)
- `docker-compose.mysql.yml` (database)

---

## Docker Internal Hostnames

### Development

Services in the same Docker network communicate via service names:

| Context | URL | Purpose |
|---------|-----|---------|
| Backend service name | `http://dev:8000` | Internal Docker hostname |
| Frontend service name | `http://dev:5173` | Same container, different port |
| Browser (on host) | `http://localhost:8000` | Access backend from your PC |
| Browser (on host) | `http://localhost:5173` | Access frontend from your PC |

### Production

With separate containers:

| Context | URL | Purpose |
|---------|-----|---------|
| Backend service name | `http://prod:8000` | Internal Docker hostname |
| Frontend service name | `http://frontend:5173` | Nginx SPA server |
| Browser (on host) | `http://localhost:8000` | Access API from your PC |
| Browser (on host) | `http://localhost:5173` | Access SPA from your PC |

## CORS Configuration in Symfony

### 1. Install CORS Bundle

```bash
composer require nelmio/cors-bundle
```

### 2. Configure CORS

In `config/packages/nelmio_cors.yaml`:

```yaml
nelmio_cors:
    defaults:
        allow_origin: ['%env(CORS_ALLOW_ORIGIN)%']
        allow_headers: ['Content-Type', 'Authorization']
        allow_methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
        max_age: 3600
        supports_credentials: true
    paths:
        '^/': ~
```

### 3. Set Environment Variable

In your Symfony `.env` or `.env.local`:

#### Development

```bash
CORS_ALLOW_ORIGIN=http://localhost:5173
```

This allows requests from your browser on localhost (running your dev frontend).

#### Production (Symfony API + SPA)

```bash
CORS_ALLOW_ORIGIN=http://frontend:5173
```

This allows requests from the Nginx SPA service within Docker network.

> **Note:** In development, the browser accesses both backend and frontend via `localhost`. In production, the frontend is a separate Nginx service, so it uses the internal Docker hostname `frontend`.

## Frontend Configuration

### Development: Vite/React/Vue/CRA

Create a `.env` file in your `frontend/` directory:

**Vite:**
```bash
VITE_API_URL=http://localhost:8000/api
```

**Next.js (dev mode):**
```bash
NEXT_PUBLIC_API_URL=http://localhost:8000/api
```

**Create React App:**
```bash
REACT_APP_API_URL=http://localhost:8000/api
```

### Production: SPA Built as Static Files

When you build your frontend for production (e.g., `npm run build`), the built files are served by **Nginx** in the `Dockerfile.spa.prod` container.

The API URL in the built SPA should still be:
```bash
VITE_API_URL=http://localhost:8000/api  # or your production domain
```

> **Key Points:**
> 1. **Development:** Vite/dev server runs inside `dev` container, but code runs in browser on `localhost`
> 2. **Production:** Built files (dist/, build/) are copied to Nginx container, still access API via domain/localhost
> 3. **Always use `localhost` for browser code** - your browser is on the host machine, not inside Docker
> 4. **Use internal Docker hostnames (`dev`, `prod`, `frontend`) only for SSR and backend-to-backend communication**

### Framework-Specific Prefixes

Each framework requires a specific prefix to expose variables to client-side code:

| Framework | Prefix | Example |
|-----------|--------|---------|
| **Vite** | `VITE_` | `VITE_API_URL` |
| **Next.js** | `NEXT_PUBLIC_` | `NEXT_PUBLIC_API_URL` |
| **CRA** | `REACT_APP_` | `REACT_APP_API_URL` |
| **Nuxt** | `NUXT_PUBLIC_` | `NUXT_PUBLIC_API_URL` |

Without the correct prefix, the variable won't be accessible in your JavaScript code.

### Using the API URL

**Vite/React:**
```javascript
const response = await fetch(`${import.meta.env.VITE_API_URL}/products`);
```

**Next.js:**
```javascript
const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/products`);
```

## Production: Nginx SPA Server

In production, your SPA is built as static files and served by **Nginx** (configured in `Dockerfile.spa.prod`).

### Nginx Configuration (`.devcontainer/config/nginx/spa.conf`)

The Nginx configuration includes:
- **Root:** `/usr/share/nginx/html` (where built files are copied)
- **Gzip compression:** Enabled for performance
- **Asset caching:** 1 year expiry for static files
- **SPA fallback:** All routes → `/index.html` (for client-side routing)
- **Health check:** Endpoint at `/health`

### Production Build Process

1. **Build frontend:**
   ```bash
   npm run build  # Creates dist/, build/, or .next/static
   ```

2. **Dockerfile.spa.prod:**
   - Stage 1: Builds your frontend (npm/yarn/pnpm)
   - Stage 2: Copies built files to Nginx
   - Result: Lightweight Nginx container serving static SPA

3. **API communication:**
   - Your built SPA calls backend at: `http://localhost:8000/api` (or your domain)
   - Nginx handles all routing to `/index.html` for client-side routing

---

## Rendering Strategies: SPA vs SSR vs ISR

**Important:** These strategies **only matter for production deployment**. In development, you always use `docker-compose.dev.yml` which runs everything in a single container regardless of your rendering choice. You choose your rendering strategy **only when deploying to production**.

This template supports three rendering strategies. Choose based on your SEO needs and application requirements:

### **SPA (Single Page Application)**

**How it works:**
- Entire app built as static files (HTML, CSS, JS)
- Browser downloads and runs JavaScript
- All logic and routing happen on the client-side
- API calls from browser to backend

**Best for:**
- React, Vue, Vite, Create React App, Astro
- Internal tools, dashboards, user portals
- When backend/frontend are separate projects

**SEO:** ⚠️ Limited (dynamic metadata requires extra work)

**Template setup:**
```bash
docker compose -f .devcontainer/docker-compose.frontend.prod.yml ...
# Uses: Dockerfile.spa.prod, Nginx server
```

---

### **SSR (Server-Side Rendering)**

**How it works:**
- HTML generated on the server for each request
- Browser receives pre-rendered HTML (with SEO metadata)
- JavaScript hydrates the page (becomes interactive)
- Perfect for SEO and performance

**Best for:**
- Next.js, Nuxt with SSR mode
- Content-heavy sites needing good SEO
- Ecommerce, blogs, marketing sites
- When server-side data fetching is needed

**SEO:** ✅ Excellent (HTML includes dynamic metadata)

**Template setup:**
```bash
docker compose -f .devcontainer/docker-compose.node.prod.yml ...
# Uses: Dockerfile.node.prod, Node.js runtime
```

---

### **ISR (Incremental Static Regeneration)**

**How it works:**
- Hybrid approach: static pages with periodic updates
- Pages pre-built at compile time (fast delivery)
- Background regeneration when content changes
- Best of both worlds: speed + fresh content

**Best for:**
- Next.js with ISR enabled
- Blogs with regular updates
- Product catalogs, documentation
- High-traffic sites needing performance

**SEO:** ✅ Excellent (static HTML with fresh content)

**Template setup:**
```bash
# In Next.js:
export async function getStaticProps() {
  return { revalidate: 3600 } // Regenerate every hour
}

# Uses: Dockerfile.node.prod (Next.js handles ISR)
```

---

### **Comparison Table**

| Feature | SPA | SSR | ISR |
|---------|-----|-----|-----|
| **Rendering** | Client-side | Server-side | Static + background |
| **Time to First Byte** | Fast | Slower | Very fast |
| **SEO** | Needs extra work | Excellent | Excellent |
| **Dynamic Content** | Via API calls | Server data | Pre-built + periodic updates |
| **Cost** | Low (static) | Medium (server) | Medium (build time) |
| **Best Framework** | React, Vue, Vite | Next.js, Nuxt | Next.js |
| **Infrastructure** | Nginx | Node.js | Node.js |

---

### **Can You Switch Between SPA/SSR/ISR Without Code Changes?**

**Short answer:** Depends on your framework choice.

| Scenario | Possible? | Details |
|----------|-----------|---------|
| **React SPA → ISR/SSR** | ❌ No | React doesn't support SSR/ISR natively. Would need complete rewrite. |
| **Next.js SPA → SSR/ISR** | ✅ Yes | Just change config in `next.config.js` and deploy to Node.js. Code stays same! |
| **Nuxt SPA → SSR** | ✅ Yes | Just enable SSR mode, code is compatible. |
| **Vite/Vue SPA → SSR** | ⚠️ Partial | Need to set up server-side rendering infrastructure. |

**Real-world example with Next.js:**
```javascript
// Same code works for all strategies:

export default function Page({ data }) {
  return <div>{data.title}</div>
}

// Dev: Deployed as SPA (client-side only)
// → npm run dev (works as SPA)
// → docker-compose.dev.yml

// Prod: Deploy as SSR
// → npm run build (builds with SSR)
// → docker-compose.node.prod.yml
// → No code changes needed!

// Prod: Deploy as ISR
// export async function getStaticProps() {
//   return { revalidate: 3600 }
// }
// → Still uses docker-compose.node.prod.yml
```

---

### **Development vs Production Setup**

```
┌─────────────────────────────────────────────────────────────┐
│                    DEVELOPMENT (Always)                     │
│                                                              │
│  docker-compose.dev.yml                                     │
│  ┌──────────────────────────────────────────────────┐      │
│  │                   dev container                   │      │
│  │  ┌────────────────┐  ┌────────────────────────┐  │      │
│  │  │ Symfony (8000) │  │ Frontend dev (5173)    │  │      │
│  │  │ Backend runs   │  │ React/Vue/Next/etc     │  │      │
│  │  │ here           │  │ dev server runs here   │  │      │
│  │  └────────────────┘  └────────────────────────┘  │      │
│  │         ▲                       ▲                 │      │
│  │         └───────────────┬───────┘                 │      │
│  │                         │                         │      │
│  │                    Same container                 │      │
│  └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
                 ↓
      (Exact same setup for all strategies)


┌─────────────────────────────────────────────────────────────┐
│             PRODUCTION (Choose ONE strategy)                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Option 1: SPA (React, Vue, Vite)                          │
│  ┌──────────────────────────────────────────────────┐      │
│  │ docker-compose.frontend.prod.yml                │      │
│  │ ┌─────────────┐         ┌──────────────────┐    │      │
│  │ │  prod       │         │ frontend         │    │      │
│  │ │  (8000)     │◄───────►│ (5173 - Nginx)   │    │      │
│  │ │  Symfony    │         │ Static SPA files │    │      │
│  │ └─────────────┘         └──────────────────┘    │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Option 2: SSR (Next.js, Nuxt)                             │
│  ┌──────────────────────────────────────────────────┐      │
│  │ docker-compose.node.prod.yml                    │      │
│  │ ┌─────────────┐         ┌──────────────────┐    │      │
│  │ │ prod        │         │ app              │    │      │
│  │ │ (8000)      │         │ (3000 - Node.js) │    │      │
│  │ │ Symfony API │         │ Server rendering │    │      │
│  │ └─────────────┘         └──────────────────┘    │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Option 3: ISR (Next.js with ISR)                          │
│  ┌──────────────────────────────────────────────────┐      │
│  │ docker-compose.node.prod.yml (same as SSR)      │      │
│  │ ┌─────────────┐         ┌──────────────────┐    │      │
│  │ │ prod        │         │ app              │    │      │
│  │ │ (8000)      │         │ (3000 - Node.js) │    │      │
│  │ │ Symfony API │         │ ISR regeneration │    │      │
│  │ └─────────────┘         └──────────────────┘    │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Changing Frontend Framework (Development)

When switching from Vite to another framework, you might need to adjust ports:

1. **For frameworks using different default ports:**
   - Vite: 5173
   - Next.js dev: 3000
   - Nuxt dev: 3000

2. **In Symfony CORS configuration:**
   ```yaml
   allow_origin: ['http://localhost:5173']  # Dev (browser access)
   # or
   allow_origin: ['http://localhost:3000']  # If using Next.js dev server
   ```

3. **Important:** In production, CORS should allow the Nginx domain/service name:
   ```yaml
   allow_origin: ['http://frontend:5173']  # Production (Nginx SPA)
   ```

## Production Deployment Scenarios

### Scenario 1: Symfony API + Static SPA

**Architecture:**
- `prod` service (Apache/PHP) on port 8000
- `frontend` service (Nginx) on port 5173
- `db` service (MySQL, internal)

**Startup:**
```bash
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.prod.yml \
  -f .devcontainer/docker-compose.frontend.prod.yml \
  up -d
```

**Frontend API calls:**
```javascript
// In your built SPA files (dist/main.js, etc.)
// Uses localhost because browser is on host machine
fetch('http://localhost:8000/api/products')
```

**Symfony CORS:**
```bash
# .env.prod
CORS_ALLOW_ORIGIN=http://frontend:5173
```

**Flow:**
1. Browser accesses `http://localhost:5173` → Nginx serves SPA
2. SPA JavaScript calls `http://localhost:8000/api/products`
3. Symfony API on `prod` service receives request
4. Nginx passes through (no CORS needed inside Docker)

---

### Scenario 2: Node.js Backend (Next.js/Nuxt SSR)

For server-side rendered applications, API calls differ:

**Development:**
```javascript
// pages/products.js (Next.js)
export async function getServerSideProps() {
  // Server-side: runs inside container, use internal hostname
  const res = await fetch('http://dev:8000/api/products')
  return { props: { products: await res.json() } }
}

export default function ProductsPage({ products }) {
  // Client-side: runs in browser
  const [clientProducts, setClientProducts] = useState(products)

  useEffect(() => {
    // Browser code: use localhost
    fetch('http://localhost:8000/api/products')
      .then(r => r.json())
      .then(setClientProducts)
  }, [])

  return ...
}
```

**Production (Node.js backend):**
```javascript
export async function getServerSideProps() {
  // Server-side in container: use internal Docker hostname
  const res = await fetch('http://prod:8000/api/products')
  return { props: { products: await res.json() } }
}
```

---

## Server-Side Rendering (SSR)

For SSR frameworks (Next.js, Nuxt running on `Dockerfile.node.prod`), API calls differ based on where they run:

```javascript
// src/pages/api.js or getServerSideProps

// ✅ Server-side code (runs in Node.js container)
const serverApiUrl = 'http://prod:8000/api'  // Internal Docker hostname

// ✅ Client-side code (runs in browser)
const clientApiUrl = 'http://localhost:8000/api'  // Browser on host machine
```

**Key distinction:**
| Location | Context | URL | Service |
|----------|---------|-----|---------|
| **Server-side** | Next.js/Nuxt server | `http://prod:8000/api` | Internal Docker name |
| **Client-side** | Browser on host | `http://localhost:8000/api` | Host machine |

## Troubleshooting

### CORS Errors in Development

**Error:** `Access-Control-Allow-Origin` header missing

**Causes & Solutions:**
1. **CORS bundle not installed:**
   ```bash
   composer require nelmio/cors-bundle
   ```

2. **CORS_ALLOW_ORIGIN doesn't match frontend URL:**
   - Development: Should be `http://localhost:5173` (browser access)
   - Production: Should be `http://frontend:5173` (Docker internal)
   - Check for typos and correct protocol (http vs https)

3. **Missing configuration:**
   - Ensure `config/packages/nelmio_cors.yaml` exists
   - Verify `supports_credentials: true` if using cookies

### CORS Errors in Production

**Error:** SPA can't reach API from Nginx container

**Solutions:**
1. **Check CORS_ALLOW_ORIGIN:**
   ```bash
   CORS_ALLOW_ORIGIN=http://frontend:5173  # Not localhost!
   ```

2. **Verify compose files are correct:**
   ```bash
   docker compose \
     -f .devcontainer/docker-compose.mysql.yml \
     -f .devcontainer/docker-compose.prod.yml \
     -f .devcontainer/docker-compose.frontend.prod.yml \
     up -d
   ```

3. **Check services are on same network:**
   ```bash
   docker network ls  # Look for app-network
   docker network inspect app-network  # Both prod and frontend should be there
   ```

### Connection Refused

**Error:** `ECONNREFUSED` when frontend calls backend

**Solutions:**
1. **Development:**
   - Use `http://localhost:8000` from browser
   - Use `http://dev:8000` from container (backend internal)
   - Check backend is running: `docker compose ps`

2. **Production:**
   - SPA accesses `http://frontend:5173` internally or `http://localhost:8000` from browser
   - Backend accesses via `http://prod:8000` internally
   - Check both services running: `docker compose ps`

3. **General:**
   - Verify both services are on same Docker network
   - Check firewall isn't blocking ports
   - Ensure correct service names (dev/prod vs frontend)

### Port Conflicts

**Error:** Port already in use

**Solutions:**
1. **Check what's using the port:**
   ```bash
   lsof -i :8000  # Linux/macOS
   netstat -ano | findstr :8000  # Windows
   ```

2. **Change ports in `.devcontainer/.env`:**
   ```bash
   BACKEND_PORT=8001  # Use different port
   ```

3. **Or stop conflicting service:**
   ```bash
   docker compose down
   ```

### Frontend Can't Access API (Development)

**Error:** 404 or ECONNREFUSED from SPA

**Checklist:**
- [ ] Backend is running: `cd backend && symfony server:start`
- [ ] Frontend dev server is running: `cd frontend && npm run dev`
- [ ] CORS is configured with `CORS_ALLOW_ORIGIN=http://localhost:5173`
- [ ] API URL in frontend code: `VITE_API_URL=http://localhost:8000/api`
- [ ] Network connection: Both services on `app-network`

### Frontend Can't Access API (Production)

**Error:** Network errors or 404 from SPA

**Checklist:**
- [ ] Both services started: `docker compose ps` shows `prod` and `frontend`
- [ ] CORS configured: `CORS_ALLOW_ORIGIN=http://frontend:5173`
- [ ] Built files deployed: Check `frontend` service logs: `docker compose logs frontend`
- [ ] API endpoint exists: Test directly: `curl http://localhost:8000/api/products`
- [ ] Network correct: `docker network inspect app-network`

## Complete Example: Symfony API + React/Vite SPA

### Development Setup

#### Backend (Symfony API)

**`backend/src/Controller/Api/ProductController.php`:**
```php
<?php
namespace App\Controller\Api;

use App\Repository\ProductRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api', name: 'api_')]
class ProductController extends AbstractController
{
    #[Route('/products', name: 'products', methods: ['GET'])]
    public function index(ProductRepository $repo): JsonResponse
    {
        return $this->json($repo->findAll());
    }
}
```

**`backend/.env`:**
```bash
# CORS configuration (matches browser access in development)
CORS_ALLOW_ORIGIN=http://localhost:5173
```

#### Frontend (React + Vite)

**`frontend/.env.local`:**
```bash
# Browser runs on host machine, accesses localhost
VITE_API_URL=http://localhost:8000/api
```

**`frontend/src/hooks/useProducts.js`:**
```javascript
import { useState, useEffect } from 'react';

export function useProducts() {
  const [products, setProducts] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Browser code: use localhost
    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

    fetch(`${apiUrl}/products`)
      .then(res => {
        if (!res.ok) throw new Error(`API error: ${res.status}`);
        return res.json();
      })
      .then(setProducts)
      .catch(setError);
  }, []);

  return { products, error };
}
```

**`frontend/src/App.jsx`:**
```jsx
import { useProducts } from './hooks/useProducts';

export default function App() {
  const { products, error } = useProducts();

  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      <h1>Products</h1>
      <ul>
        {products.map(p => <li key={p.id}>{p.name}</li>)}
      </ul>
    </div>
  );
}
```

#### Running Development

```bash
# Terminal 1: Start backend
cd backend
symfony server:start --no-tls --listen-ip=0.0.0.0 --port=8000

# Terminal 2: Start frontend
cd frontend
npm run dev -- --host
```

Then access `http://localhost:5173` in your browser.

---

### Production Setup

#### Build Frontend

```bash
cd frontend
npm run build  # Creates dist/ folder
```

#### Environment for Production

**`backend/.env.prod` or via `docker compose` env:**
```bash
# CORS allows Nginx SPA service (internal Docker hostname)
CORS_ALLOW_ORIGIN=http://frontend:5173
```

#### Docker Compose for Production

```bash
# Start both backend and frontend as separate services
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.prod.yml \
  -f .devcontainer/docker-compose.frontend.prod.yml \
  up -d
```

#### Access Production

- **API:** `http://localhost:8000/api`
- **SPA:** `http://localhost:5173`

Both URLs use localhost because you're accessing from your host machine's browser.

---

## Summary: API URLs by Context

| Context | URL | Reason |
|---------|-----|--------|
| **Browser (dev)** | `http://localhost:8000/api` | Browser on host machine |
| **Browser (prod)** | `http://localhost:8000/api` | Still your host machine |
| **Node.js server-side (dev)** | `http://dev:8000/api` | Inside Docker container |
| **Node.js server-side (prod)** | `http://prod:8000/api` | Inside Docker container |
| **Nginx (prod)** | `http://frontend:5173` | Nginx SPA service (for CORS) |

**Key Rule:** Use `localhost` for browser code, use internal service names for backend-to-backend communication.
