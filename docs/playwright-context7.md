# Playwright CLI & Context7 CLI — AI Browser & Docs Tools

Both tools are **pre-installed globally in the devcontainer** via `Dockerfile.dev`.
They require a **one-time setup** after the container starts — nothing to install, just configure.

---

## Why CLI over MCP?

Both tools exist in two flavors: a **CLI** (invoked on demand by Claude as a tool call) and an **MCP server** (a persistent process always running alongside Claude).

This template deliberately uses the **CLI approach** for the following reasons:

- **Token & context efficiency** — an MCP server injects its full schema into every conversation, even when you never use it. The CLI has zero overhead until explicitly called.
- **On-demand only** — Claude invokes the CLI only when the task actually requires it (browser inspection, doc lookup). No background noise.
- **Simpler devcontainer** — no extra process to start, no port to expose, no MCP config to maintain per project.
- **Sufficient for most use cases** — the MCP approach adds value mainly for heavy, continuous usage (e.g. a dedicated testing agent running hundreds of interactions). For development assistance, the CLI is equally capable.

> If your workflow evolves toward intensive browser automation or you hit context limits despite the CLI, switching to the MCP variant is straightforward — both packages support it.

---

## Playwright CLI

Playwright CLI (`@playwright/cli`) allows Claude Code to **control a real browser** during a conversation: open URLs, click, fill forms, take screenshots, and analyze a live UI.

This is distinct from `@playwright/test` (the E2E test runner) — see [development-tools.md](./development-tools.md) if you need E2E tests.

### First-time setup

Run once, **from the project root** (inside the devcontainer terminal):

```bash
playwright-cli install --skills
```

This installs a `playwright-cli` skill **in the current directory's `.claude/skills/`** folder. Run it from the project you want to use it in — the skill is project-scoped, not global.

### Usage

Once set up, in a Claude Code conversation:

```
→ "Open localhost:3000 and tell me what you see"
→ "Fill in the login form with admin@test.com and check the result"
→ "Take a screenshot of the /dashboard page"
→ "Verify the 'Create' button is present on /products"
```

Claude controls the browser, captures screenshots, and reports back what it observes.

> **Reference:** [github.com/microsoft/playwright-cli](https://github.com/microsoft/playwright-cli)

---

## Context7 CLI

Context7 (`ctx7`) enriches Claude Code with **up-to-date, version-specific library documentation** fetched directly from official sources.
Without it, Claude relies on its training data, which may be outdated for fast-moving libraries.

**Requires a Context7 account** — register at [context7.com](https://context7.com).

### First-time setup

Inside the devcontainer terminal, run once:

```bash
ctx7 setup --cli --claude
```

This authenticates the CLI with your Context7 account and installs a `find-docs` skill **globally** in `~/.claude/skills/` — available across all your projects automatically.

> **Using a different AI assistant?** Replace `--claude` with the flag matching your tool, or omit it entirely:
> ```bash
> ctx7 setup --cli            # no AI integration, CLI only
> ctx7 setup --cli --gemini   # for Gemini CLI (example)
> ```

### Usage

Context7 operates transparently in the background. Once configured, Claude Code automatically fetches accurate docs when generating code for supported libraries (React, Symfony, Next.js, etc.).

You can also invoke it explicitly in a conversation:

```
→ "Using Context7, show me how to configure a State Provider in API Platform 3"
→ "Get me the latest Tailwind v4 migration guide from Context7"
```

### API key (future use)

If your usage exceeds the free tier, Context7 may require an **API key**.
When that happens, add it to your environment via `.env.local` or your shell profile — refer to the [official CLI documentation](https://context7.com/docs/clients/cli) for the exact variable name.

> **References:** [context7.com/docs/clients/cli](https://context7.com/docs/clients/cli) — [upstash/context7 on GitHub](https://github.com/upstash/context7/tree/master/packages/cli)

---

## Summary

| Tool | Pre-installed | Setup command | Requires account |
|------|:---:|---|:---:|
| Playwright CLI | Yes | `playwright-cli install --skills` | No |
| Context7 CLI | Yes | `ctx7 setup --cli --claude` | Yes |

Both commands are idempotent — safe to re-run if needed.

---

## Removing these tools

Both tools add installation time to the devcontainer build (npm global installs + Chromium browser dependencies). If you don't need them, remove the following two blocks from `.devcontainer/Dockerfile.dev` and rebuild the container.

**Block 1** — inside the main `RUN` layer:

```dockerfile
# Installation globale playwright cli et context7 cli
&& npm install -g @playwright/cli@latest \
&& npm install -g ctx7 \
```

**Block 2** — the dedicated Playwright browser dependencies layer:

```dockerfile
# Install Playwright browser dependencies
RUN npx playwright install-deps chromium
```

Then rebuild the devcontainer (`Ctrl+Shift+P` → **Dev Containers: Rebuild Container**).
