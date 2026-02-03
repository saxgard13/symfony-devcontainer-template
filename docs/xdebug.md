# Xdebug Configuration

Xdebug is pre-configured for step debugging in VS Code.

## Finding Your Host IP

Xdebug needs to know how to reach your host machine.

### macOS & Windows (Docker Desktop)

Use the special Docker internal host:

```ini
xdebug.client_host=host.docker.internal
```

This works automatically on Docker Desktop.

### Linux

Linux does **not** support `host.docker.internal` by default. Find your host IP manually:

```bash
ip a | grep inet
```

Look for a line like:

```
inet 10.0.2.15/24 brd ...
```

Use this IP (e.g., `10.0.2.15`).

## Configuration Files

### PHP Configuration

In `.devcontainer/config/php.ini`:

```ini
xdebug.mode=debug
xdebug.client_host=host.docker.internal  ; or your Linux IP
xdebug.client_port=9003
xdebug.start_with_request=yes
```

### VS Code Launch Configuration

In `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/workspace/backend": "${workspaceFolder}"
      }
    }
  ]
}
```

If on Linux, add environment override:

```json
{
  "name": "Listen for Xdebug",
  "type": "php",
  "request": "launch",
  "port": 9003,
  "env": {
    "XDEBUG_MODE": "debug,develop",
    "XDEBUG_CONFIG": "client_host=10.0.2.15 client_port=9003"
  }
}
```

## Applying Changes

After modifying configuration, rebuild the container:

1. Open Command Palette (`Ctrl+Shift+P`)
2. Select "Dev Containers: Rebuild Container"

## Using Xdebug

1. Set breakpoints in your PHP files (click left of line number)
2. Start the debugger in VS Code (F5 or Run → Start Debugging)
3. Make a request to your application
4. VS Code will pause at breakpoints

## Troubleshooting

### Debugger Not Connecting

1. Verify Xdebug is loaded:
   ```bash
   php -v
   # Should show "with Xdebug v3.x.x"
   ```

2. Check configuration:
   ```bash
   php -i | grep xdebug
   ```

3. Verify port 9003 is not blocked by firewall

### Wrong Path Mappings

If breakpoints don't work, check `pathMappings` in `launch.json`:

- Left side: path inside container (`/workspace/backend`)
- Right side: path in VS Code (`${workspaceFolder}`)

### Linux: host.docker.internal Not Working

Add this to your Docker run command or compose file:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

Or use your actual IP address instead.
