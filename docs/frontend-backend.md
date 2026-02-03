# Frontend ↔ Backend Communication

This guide explains how to configure communication between Symfony (API) and a frontend framework (React, Vue, Next.js, etc.) inside Docker containers.

> **Note:** This setup assumes Vite (port 5173). For other frameworks, adjust ports accordingly.

## Docker Internal Hostnames

Services in the same Docker network communicate via service names:

| Context | URL | Notes |
|---------|-----|-------|
| Backend container | `http://dev:8000` | Docker backend service name |
| Frontend container | `http://frontend:5173` | Default Vite port |
| Browser (host) | `http://localhost:8000` | Backend access |
| Browser (host) | `http://localhost:5173` | Frontend access |

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

```bash
CORS_ALLOW_ORIGIN=http://frontend:5173
```

This tells Symfony to accept requests from the frontend container.

## Frontend Configuration

### API URL Setup

Create a `.env` file in your frontend:

**Vite:**
```bash
VITE_API_URL=http://localhost:8000/api
```

**Next.js:**
```bash
NEXT_PUBLIC_API_URL=http://localhost:8000/api
```

**Create React App:**
```bash
REACT_APP_API_URL=http://localhost:8000/api
```

> **Why different variable names?** Each framework requires a specific prefix to expose variables to client-side code:
> - Vite: `VITE_`
> - Next.js: `NEXT_PUBLIC_`
> - CRA: `REACT_APP_`
>
> Without the correct prefix, the variable won't be accessible in your JavaScript code.

> **Why `localhost` and not `dev`?** The frontend code runs in your **browser** (on your host machine), not inside Docker. Your browser doesn't know about Docker's internal network and can't resolve `dev`. Use `localhost` for client-side code, and `dev` only for server-side code (SSR).

### Using the API URL

**Vite/React:**
```javascript
const response = await fetch(`${import.meta.env.VITE_API_URL}/products`);
```

**Next.js:**
```javascript
const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/products`);
```

## Changing Frontend Framework

When switching from Vite to another framework (e.g., Next.js), update:

1. **`.devcontainer/.env`:**
   ```bash
   FRONTEND_INTERNAL_PORT=3000  # Next.js default
   ```

2. **Symfony CORS:**
   ```bash
   CORS_ALLOW_ORIGIN=http://frontend:3000
   ```

3. **`nelmio_cors.yaml`** (if hardcoded):
   ```yaml
   allow_origin: ['http://frontend:3000']
   ```

## Server-Side Rendering (SSR)

For SSR frameworks (Next.js, Nuxt), API calls from the server need the internal Docker hostname:

```javascript
// Server-side (runs inside container)
const apiUrl = process.env.NODE_ENV === 'production'
  ? 'http://dev:8000/api'      // Internal Docker hostname
  : 'http://localhost:8000/api' // Development fallback

// Client-side (runs in browser)
const clientApiUrl = 'http://localhost:8000/api'
```

## Troubleshooting

### CORS Errors

**Error:** `Access-Control-Allow-Origin` header missing

**Solutions:**
1. Verify CORS bundle is installed and configured
2. Check `CORS_ALLOW_ORIGIN` matches frontend URL exactly
3. Ensure `supports_credentials: true` if using cookies

### Connection Refused

**Error:** `ECONNREFUSED` when frontend calls backend

**Solutions:**
1. Verify backend is running on correct port
2. Use `http://localhost:8000` from browser, `http://dev:8000` from container
3. Check both services are on same Docker network

### Port Conflicts

**Error:** Port already in use

**Solutions:**
1. Change ports in `.devcontainer/.env`
2. Stop conflicting services on host
3. Use different `FRONTEND_LOCALHOST_PORT`

## Example: Full Stack Setup

### Backend (Symfony API)

```php
// src/Controller/Api/ProductController.php
#[Route('/api/products', name: 'api_products')]
public function index(ProductRepository $repo): JsonResponse
{
    return $this->json($repo->findAll());
}
```

### Frontend (React + Vite)

```javascript
// src/hooks/useProducts.js
export function useProducts() {
  const [products, setProducts] = useState([]);

  useEffect(() => {
    fetch(`${import.meta.env.VITE_API_URL}/products`)
      .then(res => res.json())
      .then(setProducts);
  }, []);

  return products;
}
```

### Environment Files

**Symfony `.env`:**
```bash
CORS_ALLOW_ORIGIN=http://frontend:5173
```

**Vite `.env`:**
```bash
VITE_API_URL=http://localhost:8000/api
```
