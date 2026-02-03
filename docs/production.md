# Production Build

This document explains the production-like configuration for testing before deployment.

> **Important:** This configuration is for **local testing in a production-like environment**, not for actual deployment. Use it to validate your application before deploying to real infrastructure.

## Production Dockerfile

The production image is at `.devcontainer/Dockerfile.apache.prod`.

### Features

- **Multi-stage build**: Separates build from runtime for smaller images
- **Optimized caching**: Dependencies cached separately from code
- **Security headers**: Apache preconfigured with security headers
- **Non-root user**: Apache runs as `www-data`
- **No dev tools**: Xdebug and dev dependencies excluded

### Build Stages

```dockerfile
# Stage 1: Builder
FROM php:8.3-cli AS builder
# Install Composer, copy composer.json, install dependencies
# This layer is cached if composer.* files don't change

# Stage 2: Runtime
FROM php:8.3-apache
# Copy only production files, configure Apache
```

## Building the Production Image

```bash
docker build -f .devcontainer/Dockerfile.apache.prod -t my-app:prod .
```

### With Build Arguments

```bash
docker build \
  -f .devcontainer/Dockerfile.apache.prod \
  --build-arg PHP_VERSION=8.3 \
  -t my-app:prod .
```

## Running Production Container

### Using Docker Compose

```bash
docker compose -f .devcontainer/docker-compose.prod.yml up -d
```

Access at `http://localhost:8081`

### Standalone

```bash
docker run -d \
  -p 8081:80 \
  -e APP_ENV=prod \
  -e APP_DEBUG=0 \
  -e DATABASE_URL="mysql://user:pass@db:3306/mydb" \
  my-app:prod
```

## Layer Caching Optimization

The Dockerfile is optimized for Docker layer caching:

```dockerfile
# 1. Copy dependency files (cached if unchanged)
COPY backend/composer.json backend/composer.lock* ./backend/

# 2. Install dependencies (cached if composer.* unchanged)
RUN cd backend && composer install --no-dev --optimize-autoloader

# 3. Copy source code (rebuilt on every code change)
COPY . .
```

**Benefits:**
- Dependencies only reinstalled when `composer.json` changes
- Code changes don't invalidate dependency cache
- Faster builds during development

## Production Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `APP_ENV` | `prod` | Symfony production mode |
| `APP_DEBUG` | `0` | Disable debug output |
| `DATABASE_URL` | Connection string | Production database |

## PHP Production Settings

The production PHP config (`.devcontainer/config/php.ini.prod`) includes:

| Setting | Value | Purpose |
|---------|-------|---------|
| `display_errors` | `Off` | Never show errors to users |
| `expose_php` | `Off` | Hide PHP version |
| `opcache.validate_timestamps` | `0` | No file checks (faster) |
| `opcache.memory_consumption` | `256` | More cache memory |

## Production Checklist

Before deploying to real production:

- [ ] Change all default passwords
- [ ] Configure real SSL certificates
- [ ] Set up proper logging and monitoring
- [ ] Configure load balancing if needed
- [ ] Set up database backups
- [ ] Review and adjust `Content-Security-Policy`
- [ ] Enable HSTS for HTTPS
- [ ] Set up health checks
- [ ] Configure rate limiting
- [ ] Review file upload limits

## Volumes in Production

The production compose file uses persistent volumes:

```yaml
volumes:
  - uploads:/var/www/html/public/uploads  # User uploads
  - logs:/var/log/apache2                  # Apache logs
```

## Database in Production

The production database has **no exposed ports** for security:

```yaml
db:
  image: mysql:8.3
  # No "ports:" section
  # Only accessible via SSH tunnel or within Docker network
```

See [Database Configuration](database.md#production-database-access) for SSH tunnel setup.

## Deployment Notes

This template provides a foundation, but real production requires additional considerations:

- **Orchestration**: Consider Kubernetes, Docker Swarm, or managed services
- **CI/CD**: Set up automated builds and deployments
- **Secrets Management**: Use Docker secrets or external vaults
- **Networking**: Configure proper DNS, reverse proxies, load balancers
- **Monitoring**: Set up APM, log aggregation, alerting
- **Scaling**: Plan for horizontal scaling if needed
