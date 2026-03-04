# Xdebug Configuration

Xdebug is pre-configured for step debugging in VS Code with `trigger` mode — it only activates when explicitly triggered, so CLI tools (Composer, PHPStan, etc.) are not affected.

## Current Configuration

In `.devcontainer/config/php.ini`:

```ini
xdebug.mode=develop,debug
xdebug.start_with_request=trigger
xdebug.client_host=127.0.0.1
xdebug.client_port=9003
```

## VS Code Launch Configuration

The debugger configuration is defined in:

- `.vscode/launch.json` — used when opening the project without a code-workspace
- `project.code-workspace` — used with the multi-root workspace (Backend + Frontend + Shared)
- `backend.code-workspace` — used with the backend-only workspace

The `pathMappings` are automatically updated by `scripts/update-config.sh` when `project_name` changes.

## Starting the Debugger

1. Set breakpoints in your PHP files (click left of line number)
2. Start listening: **F5** or **Run → Start Debugging → "Listen for Xdebug"**
3. Trigger a request (see below)
4. VS Code will pause at breakpoints

## Triggering Xdebug

Since `start_with_request=trigger`, Xdebug only activates when a trigger is present.

### From the browser

Add the query parameter to the URL:

```
http://localhost:8000/?XDEBUG_SESSION=1
```

The `XDEBUG_SESSION` cookie is then set for subsequent requests on the same domain — no need to add the parameter to every URL.

To stop debugging, clear the cookie or add:

```
http://localhost:8000/?XDEBUG_SESSION_STOP=1
```

### From the CLI

```bash
XDEBUG_TRIGGER=1 php bin/console my:command
XDEBUG_TRIGGER=1 symfony console my:command
```

## Linux: client_host

On Linux, `127.0.0.1` works because the Symfony server runs inside the same container where VS Code is attached. No extra configuration is needed.

If you run the Symfony server outside the container, use your host IP:

```bash
ip a | grep inet
```

And update `php.ini`:

```ini
xdebug.client_host=<your-host-ip>
```

## Troubleshooting

### Debugger not connecting

1. Verify Xdebug is loaded:
   ```bash
   php -v
   # Should show "with Xdebug v3.x.x"
   ```

2. Check the debugger is listening in VS Code (green play button in Run & Debug panel)

3. Make sure the trigger is present (`?XDEBUG_SESSION=1` in URL)

### Breakpoints not hit

Check `pathMappings` — the left side must match the exact path inside the container:

```
/workspace-<project_name>/backend  →  ${workspaceFolder}
```

Run `bash scripts/update-config.sh` to ensure all path mappings are up to date.
