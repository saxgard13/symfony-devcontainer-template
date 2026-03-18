#!/bin/bash

# Clean cache only if requested
if [ "$CLEAN_VSCODE_EXTENSIONS" = "true" ]; then
  echo "Cleaning VS Code extensions cache..."
  rm -rf /home/vscode/.vscode-server/extensions/*
fi

# --- Claude Code Installation ---
CLAUDE_VER="Not installed"

# Condition:
# (JSON file exists AND is not empty)
# OR
# (directory exists AND contains at least one file/subdirectory)
if ([ -s "$HOME/.claude.json" ]) || ([ -d "$HOME/.claude" ] && [ "$(ls -A "$HOME/.claude" 2>/dev/null)" ]); then

  # IMPORTANT: Set PATH for the current script session
  export PATH="$HOME/.local/bin:$HOME/.claude-code/bin:$PATH"

  # Only install if the binary is not already present
  if ! command -v claude &> /dev/null; then
      echo "→ Claude config detected. Installing CLI..."
      # Silent installation
      curl -fsSL https://claude.ai/install.sh | bash > /dev/null 2>&1
  fi

  # Persist PATH in .bashrc
  if ! grep -q ".claude-code/bin" "$HOME/.bashrc"; then
      echo 'export PATH="$HOME/.local/bin:$HOME/.claude-code/bin:$PATH"' >> "$HOME/.bashrc"
  fi

  # Retrieve version for the summary table
  # Use 'command -v' to ensure the binary is accessible
  if command -v claude &> /dev/null; then
      CLAUDE_VER=$(claude --version 2>/dev/null | head -n 1)
  else
      CLAUDE_VER="Installed (Reload terminal)"
  fi
fi

# Collect versions silently at the beginning
PHP_VER=$(php -r 'echo PHP_VERSION;')
SYMFONY_VER=$(symfony -V 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' | head -1)
COMPOSER_VER=$(composer -V 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
NODE_VER=$(node -v)
NPM_VER=$(npm -v)
# Retrieve the clean Claude version
CLAUDE_VER=$(claude --version 2>/dev/null || echo "Not installed")

# Load .env.local
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a
if [ -f "$SCRIPT_DIR/.env.local" ]; then
  source "$SCRIPT_DIR/.env.local"
else
  echo ""
  echo "WARNING: The .env.local file does not exist!"
  echo "Create it from .env.local.example with your Git information."
  echo ""
  echo "Example:"
  echo "  GIT_USER_NAME=\"Your Name\""
  echo "  GIT_USER_EMAIL=\"your@email.com\""
  echo ""
fi
set +a

# Caddy exports root.crt to config/caddy/export/ via its entrypoint wrapper
# Nothing to do here — the file is already accessible on the host for browser import

# Git configuration if variables are defined
GIT_INFO=""
if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  GIT_INFO="$GIT_USER_NAME <$GIT_USER_EMAIL>"
fi


# Wait a bit for VS Code logs to settle down
sleep 15

# Display everything in a single buffered output at the end
{
  echo ""
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║              DEV ENVIRONMENT READY                          ║"
  echo "╠════════════════════════════════════════════════════════════╣"
  printf "║  PHP      : %-47s ║\n" "$PHP_VER"
  printf "║  Symfony  : %-47s ║\n" "$SYMFONY_VER"
  printf "║  Composer : %-47s ║\n" "$COMPOSER_VER"
  printf "║  Node     : %-47s ║\n" "$NODE_VER"
  printf "║  NPM      : %-47s ║\n" "$NPM_VER"
  printf "║  Claude   : %-46s ║\n" "$CLAUDE_VER"
  if [ -n "$GIT_INFO" ]; then
    echo "╠════════════════════════════════════════════════════════════╣"
    printf "║  Git      : %-47s ║\n" "$GIT_INFO"
  fi
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
}
