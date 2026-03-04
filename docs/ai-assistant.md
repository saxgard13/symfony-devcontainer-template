# AI Assistant in Devcontainer

## Current setup: Claude Code

This template is preconfigured for [Claude Code](https://claude.ai/code), Anthropic's AI assistant integrated into VS Code and available as a CLI.

### What is configured

**Config persistence across rebuilds** — `devcontainer.json` mounts Claude's config files from the host into the container:

```json
"mounts": [
    "source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.claude.json,target=/home/vscode/.claude.json,type=bind,consistency=cached"
]
```

This means everything you configure at the **user level** (`~/.claude/`) survives container rebuilds:

- Authentication tokens
- MCP servers (database clients, GitHub, Notion, etc.)
- Custom skills (e.g. `/commit`, `/review-pr`)
- Subagents
- Auto-memory and conversation history
- Global settings

**Auto-creation if missing** — `init.sh` creates the files on the host before the container starts, so the mount never fails on a fresh machine:

```bash
if [ ! -d "$HOME/.claude" ]; then mkdir -p "$HOME/.claude"; fi
if [ ! -f "$HOME/.claude.json" ]; then echo '{}' > "$HOME/.claude.json"; fi
```

**Project memory isolation** — each project gets a unique path inside the container via `docker-compose.dev.yml` and `devcontainer.json`:

```yaml
# docker-compose.dev.yml — reads PROJECT_NAME from .devcontainer/.env automatically
- ..:/workspace-${PROJECT_NAME}:cached
```

```json
// devcontainer.json — updated by scripts/update-config.sh
"workspaceFolder": "/workspace-project-name"
```

Claude Code identifies projects by their absolute path in the container. Since each project has a unique path (`/workspace-project-name`, `/workspace-myblog`, etc.), `~/.claude/projects/` keeps a separate memory entry per project — while auth, settings, MCP servers and skills remain shared.

To apply the correct path when setting up a new project from this template:

```bash
# 1. Set project_name in .config.json
# 2. Run:
bash scripts/update-config.sh
# 3. Rebuild the devcontainer
```

### Starting the Claude Code extension after opening the devcontainer

The Claude Code extension does **not start automatically**. Activate it manually:

1. Open the command palette: `Ctrl+Shift+P`
2. Type `Claude` and select **Claude: Open Claude**

Or click directly on the Claude icon in the VS Code sidebar.

> If the extension is not installed, it is available on the [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code).

### CLI usage on the host

The Claude Code CLI can be installed on the **host machine** independently of the devcontainer:

```bash
curl -fsSL https://claude.ai/install.sh | bash
claude  # authenticate here
```

> The `npm install -g @anthropic-ai/claude-code` method also works but is deprecated.

The **VS Code extension is the recommended approach** inside the devcontainer — it works out of the box with the mounts and requires no additional setup.

---

## Switching to a different AI

The same principle applies to any AI assistant that stores its configuration in `~/` on the host.

### Example: Gemini CLI

[Gemini CLI](https://github.com/google-gemini/gemini-cli) stores its config in `~/.gemini/`.

**1. Add the mount in `devcontainer.json`:**

```json
"source=${localEnv:HOME}/.gemini,target=/home/vscode/.gemini,type=bind,consistency=cached"
```

**2. Add the creation in `init.sh`:**

```bash
if [ ! -d "$HOME/.gemini" ]; then
  mkdir -p "$HOME/.gemini"
fi
```

### Generic pattern

For any tool storing its config in `~/.tool-name/`:

1. Identify the config folder
2. Add the mount in `devcontainer.json`
3. Add the creation in `init.sh`
4. Rebuild the container
