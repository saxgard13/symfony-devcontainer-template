# Security

This document covers security practices for the DevContainer template.

## Credentials Security

The default credentials are for **local development only**. Never use them in production.

### Environment Variable Substitution

Database credentials use defaults with override capability:

```yaml
MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-roots}
MYSQL_USER: ${MYSQL_USER:-symfony}
MYSQL_PASSWORD: ${MYSQL_PASSWORD:-symfony}
```

- If variable is defined → use its value
- Otherwise → use the default

### Securing Credentials

1. Create `.devcontainer/.env.local` (gitignored)
2. Define strong passwords:

```bash
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_USER=your_app_user
MYSQL_PASSWORD=your_secure_app_password
```

## Apache Security Headers

The Apache configuration (`.devcontainer/config/apache/vhost.conf`) includes security headers:

| Header | Protection |
|--------|------------|
| `X-Frame-Options: DENY` | Clickjacking |
| `X-Content-Type-Options: nosniff` | MIME type sniffing |
| `X-XSS-Protection: 1; mode=block` | XSS (legacy browsers) |
| `Referrer-Policy: strict-origin-when-cross-origin` | URL information leakage |
| `Content-Security-Policy` | XSS, code injection |

## Apache HTTPS Configuration

For production with HTTPS, add to your Apache config:

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

    # Security Headers
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

> **Note:** For local development, use `symfony serve` which handles HTTPS automatically.

## Docker Ignore

The `.dockerignore` prevents sensitive files from being included in production images:

| Pattern | Reason |
|---------|--------|
| `.git`, `.gitignore` | Version control metadata |
| `.env.local`, `.env.*.local` | Local secrets |
| `.env.prod`, `.env.*.prod` | Production secrets |
| `node_modules/`, `vendor/` | Dependencies (reinstalled in container) |
| `var/cache/`, `var/log/` | Temporary files |
| `.vscode/`, `.idea/` | IDE configurations |

## SSH Keys in DevContainer

The template mounts `~/.ssh` from your host, allowing secure Git operations.

### Verify Keys

```bash
ls -l ~/.ssh        # List keys in container
ssh -T git@github.com  # Test GitHub access
```

### Security Notes

- Keys remain on your host machine
- Never added to the project or repository
- Each user keeps their own key names (`id_rsa`, `id_ed25519`, etc.)

## Production Database Access

Never expose your database port publicly. Use SSH tunnels instead.

See [Database Configuration](database.md#production-database-access) for SSH tunnel setup.

## Container Security

### Non-root User

The development container runs as `vscode` user (UID 1000), not root.

### Production Container

The production container runs Apache as `www-data` user.

### No Exposed Database Ports

In production compose, the database has no port mapping:

```yaml
db:
  # No "ports:" section = only accessible within Docker network
```

## HTTPS in Production with Nginx Reverse Proxy

For production environments requiring HTTPS, use an **Nginx reverse proxy in front of your services**. This approach keeps your existing Apache and service configurations unchanged while adding SSL/TLS layer.

### Architecture

```
Browser (HTTPS)
    ↓ https://localhost:443
Nginx Reverse Proxy (SSL/TLS termination)
    ↓ HTTP reverse proxy
    ├─ http://prod:8000 (Apache + Symfony API)
    └─ http://frontend:80 (Frontend SPA or Node.js SSR)
```

### Setup Steps

**1. Create `docker-compose.https.prod.yml`:**

```yaml
services:
  nginx-ssl:
    image: nginx:alpine
    ports:
      - "80:80"        # HTTP → redirects to HTTPS
      - "443:443"      # HTTPS
    volumes:
      - ./certs/:/etc/nginx/certs/
      - ./config/nginx/ssl.conf:/etc/nginx/conf.d/default.conf
    networks:
      - app-network
    depends_on:
      - frontend
      - prod
    restart: unless-stopped

networks:
  app-network:
    external: true
    name: devcontainer-network
```

**2. Create `config/nginx/ssl.conf`:**

```nginx
# HTTP → HTTPS Redirect
server {
  listen 80;
  server_name _;

  # Redirect all HTTP traffic to HTTPS
  return 301 https://$host$request_uri;
}

# HTTPS Server
server {
  listen 443 ssl http2;
  server_name _;

  # SSL Configuration
  ssl_certificate /etc/nginx/certs/cert.pem;
  ssl_certificate_key /etc/nginx/certs/key.pem;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers HIGH:!aNULL:!MD5;
  ssl_prefer_server_ciphers on;

  # HSTS - Force HTTPS for 1 year
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

  # Security Headers
  add_header X-Frame-Options "DENY" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-XSS-Protection "1; mode=block" always;
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;

  # API Reverse Proxy
  location /api/ {
    proxy_pass http://prod:8000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-Host $server_name;
  }

  # Frontend Reverse Proxy
  location / {
    proxy_pass http://frontend:80;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-Host $server_name;
  }
}
```

**3. Generate Self-Signed Certificates (for testing):**

```bash
mkdir -p .devcontainer/certs
openssl req -x509 -newkey rsa:4096 -keyout .devcontainer/certs/key.pem \
  -out .devcontainer/certs/cert.pem -days 365 -nodes
```

**4. Launch with HTTPS:**

```bash
docker compose \
  -f .devcontainer/docker-compose.mysql.yml \
  -f .devcontainer/docker-compose.frontend.prod.yml \
  -f .devcontainer/docker-compose.https.prod.yml \
  up -d
```

### Key Benefits

- **No changes to Apache:** VirtualHost configuration remains unchanged
- **Transparent to services:** Backend and frontend don't know about HTTPS
- **HTTP → HTTPS redirect:** All HTTP traffic automatically redirects
- **HSTS enabled:** Browsers remember to use HTTPS
- **Modular:** Add/remove HTTPS layer by including/excluding the compose file

### Important Notes

1. **`X-Forwarded-Proto: https` header:** Services receive this header so they know the client connection is HTTPS (important for Symfony URL generation)

2. **Self-signed certificates:** For production, use Let's Encrypt or your CA's certificates instead

3. **No Apache changes:** Apache continues to listen on port 80 internally. Nginx handles all HTTPS/TLS termination

4. **Port exposure:** Only Nginx exposes ports (80, 443). Backend and frontend ports are not exposed directly

---

## Security Checklist

- [ ] Change default database credentials in `.env.local`
- [ ] Never commit `.env.local` or `.env.prod`
- [ ] Use SSH tunnels for production database access
- [ ] Disable password authentication on production servers
- [ ] Review Content-Security-Policy for your application needs
- [ ] Use HTTPS in production with valid certificates
- [ ] Keep Docker images updated
- [ ] For HTTPS production: Generate proper SSL certificates (not self-signed)
- [ ] For HTTPS production: Configure Nginx reverse proxy as documented
- [ ] Ensure `X-Forwarded-Proto` header is properly set in reverse proxy
