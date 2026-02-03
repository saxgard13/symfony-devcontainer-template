#!/bin/bash

# Nettoyer le cache uniquement si demandé
if [ "$CLEAN_VSCODE_EXTENSIONS" = "true" ]; then
  echo "Nettoyage du cache des extensions VS Code..."
  rm -rf /home/vscode/.vscode-server/extensions/*
fi

# Collecter les versions silencieusement au debut
PHP_VER=$(php -r 'echo PHP_VERSION;')
SYMFONY_VER=$(symfony -V 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' | head -1)
COMPOSER_VER=$(composer -V 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
NODE_VER=$(node -v)
NPM_VER=$(npm -v)

# Charger .env.local
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a
if [ -f "$SCRIPT_DIR/.env.local" ]; then
  source "$SCRIPT_DIR/.env.local"
else
  echo ""
  echo "ATTENTION: Le fichier .env.local n'existe pas!"
  echo "Creez-le depuis .env.local.example avec vos informations Git."
  echo ""
  echo "Exemple:"
  echo "  GIT_USER_NAME=\"Votre Nom\""
  echo "  GIT_USER_EMAIL=\"votre@email.com\""
  echo ""
fi
set +a

# Configuration Git si les variables sont definies
GIT_INFO=""
if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  GIT_INFO="$GIT_USER_NAME <$GIT_USER_EMAIL>"
fi

# Attendre un peu que les logs VS Code se calment
sleep 15

# Afficher tout en une seule sortie bufferisee a la fin
{
  echo ""
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║              ENVIRONNEMENT DE DEV PRET                     ║"
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
