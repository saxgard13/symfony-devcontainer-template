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

## Security Checklist

- [ ] Change default database credentials in `.env.local`
- [ ] Never commit `.env.local` or `.env.prod`
- [ ] Use SSH tunnels for production database access
- [ ] Disable password authentication on production servers
- [ ] Review Content-Security-Policy for your application needs
- [ ] Use HTTPS in production with valid certificates
- [ ] Keep Docker images updated
