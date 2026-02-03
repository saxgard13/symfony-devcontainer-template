#!/bin/bash

# Clean cache only if requested
if [ "$CLEAN_VSCODE_EXTENSIONS" = "true" ]; then
  echo "Cleaning VS Code extensions cache..."
  rm -rf /home/vscode/.vscode-server/extensions/*
fi

# Collect versions silently at the beginning
PHP_VER=$(php -r 'echo PHP_VERSION;')
SYMFONY_VER=$(symfony -V 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' | head -1)
COMPOSER_VER=$(composer -V 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
NODE_VER=$(node -v)
NPM_VER=$(npm -v)

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
  if [ -n "$GIT_INFO" ]; then
    echo "╠════════════════════════════════════════════════════════════╣"
    printf "║  Git      : %-47s ║\n" "$GIT_INFO"
  fi
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
}
