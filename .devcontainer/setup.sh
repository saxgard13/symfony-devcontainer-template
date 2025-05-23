#!/bin/bash

# Nettoyer le cache des extensions serveur pour éviter conflits (optionnel)
rm -rf /home/vscode/.vscode-server/extensions/*

php -v
symfony -v
composer -V

echo "node: $(node -v)"
echo "npm:  $(npm -v)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a
source "$SCRIPT_DIR/.env.local"
set +a

# Configuration Git si les variables sont définies
if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  echo "Git configuré avec : $GIT_USER_NAME <$GIT_USER_EMAIL>"
else
  echo "⚠️  GIT_USER_NAME ou GIT_USER_EMAIL non définis, configuration Git ignorée."
fi

