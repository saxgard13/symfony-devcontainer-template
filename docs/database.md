# Database Configuration

This DevContainer supports MySQL, MariaDB, and PostgreSQL.

## Default Connection

| Setting | Value |
|---------|-------|
| Host | `db` |
| MySQL/MariaDB Port | 3306 |
| PostgreSQL Port | 5432 |
| Username | `symfony` |
| Password | `symfony` |
| Database | `{PROJECT_NAME}_db` |

The `PROJECT_NAME` is defined in `.devcontainer/.env`.

## Switching Database Engine

### Step 1: Update devcontainer.json

Change the database compose file:

```json
"dockerComposeFile": [
  "docker-compose.dev.yml",
  "docker-compose.mysql.yml"    // or "docker-compose.postgre.yml"
],
```

### Step 2: Update .env variables

**MySQL:**
```bash
DB_IMAGE=mysql:8.3
SERVER_VERSION=8.3
```

**MariaDB:**
```bash
DB_IMAGE=mariadb:10.11
SERVER_VERSION=mariadb-10.11
```

**PostgreSQL:**
```bash
DB_IMAGE=postgres:16
SERVER_VERSION=   # Leave empty for PostgreSQL
```

### Step 3: Update DATABASE_URL

In your Symfony `.env`:

**MySQL/MariaDB:**
```bash
DATABASE_URL=mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@db:3306/${PROJECT_NAME}_db?serverVersion=${SERVER_VERSION}
```

**PostgreSQL:**
```bash
DATABASE_URL=pgsql://${MYSQL_USER}:${MYSQL_PASSWORD}@db:5432/${PROJECT_NAME}_db
```

> **Note:** The variables `${MYSQL_USER}` and `${MYSQL_PASSWORD}` are defined in `.devcontainer/.env` (defaults) or `.devcontainer/.env.local` (your overrides).

### Step 4: Rebuild the container

Press `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"

## Adminer (Database GUI)

Access Adminer at `http://localhost:8080`

| Field | Value |
|-------|-------|
| System | MySQL / PostgreSQL |
| Server | `db` |
| Username | `symfony` |
| Password | `symfony` |
| Database | `{PROJECT_NAME}_db` |

## Production Database Access

In production, the database should **never be exposed publicly**. Use an SSH tunnel.

### Creating an SSH Tunnel

From your **local machine** (not the server):

```bash
ssh -L 3307:db:3306 user@your-server.com
#      │    │   │
#      │    │   └── MySQL port in Docker container
#      │    └────── Docker service name
#      └─────────── Local port on your PC
```

### Connecting via CLI

In another terminal:

```bash
mysql -h 127.0.0.1 -P 3307 -u symfony_prod -p
```

### Connecting via GUI Tools

(DBeaver, TablePlus, MySQL Workbench)

| Setting | Value |
|---------|-------|
| Host | `127.0.0.1` |
| Port | `3307` |
| User | `symfony_prod` |
| Password | your password |

Close the SSH session to terminate access.

## SSH Key Setup

SSH keys provide secure, password-less authentication.

### Generate Keys

On your **local PC**:

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
# Press Enter for default path, then set a passphrase
```

### Copy Public Key to Server

```bash
ssh-copy-id user@your-server.com

# Or manually:
cat ~/.ssh/id_ed25519.pub | ssh user@your-server.com "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Test Connection

```bash
ssh user@your-server.com
# Should connect without password
```

### Secure the Server

Edit `/etc/ssh/sshd_config` on the server:

```bash
PasswordAuthentication no
PermitRootLogin no
```

Then restart SSH:

```bash
sudo systemctl restart sshd
```

| File | Location | Share? |
|------|----------|--------|
| `~/.ssh/id_ed25519` (private) | Local PC only | **NEVER** |
| `~/.ssh/id_ed25519.pub` (public) | Local PC + Server | Yes |
