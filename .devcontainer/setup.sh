#!/bin/bash

# Nettoyer le cache uniquement si demandé
if [ "$CLEAN_VSCODE_EXTENSIONS" = "true" ]; then
  echo "Nettoyage du cache des extensions VS Code..."
  rm -rf /home/vscode/.vscode-server/extensions/*
fi

# Afficher les versions
echo "Versions installees:"
php -v
symfony -v
composer -V
echo "node: $(node -v)"
echo "npm:  $(npm -v)"

# Charger .env.local
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a
if [ -f "$SCRIPT_DIR/.env.local" ]; then
  source "$SCRIPT_DIR/.env.local"
else
  echo "Fichier .env.local non trouve, configuration Git ignoree."
fi
set +a

# Configuration Git si les variables sont definies
if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  echo "Git configure: $GIT_USER_NAME <$GIT_USER_EMAIL>"
else
  echo "GIT_USER_NAME ou GIT_USER_EMAIL non definis, configuration Git ignoree."
fi
