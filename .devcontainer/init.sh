#!/bin/bash

# Créer le dossier .symfony5 sur l'hôte s'il n'existe pas (pour les certificats HTTPS)
SYMFONY_DIR="$HOME/.symfony5"
if [ ! -d "$SYMFONY_DIR" ]; then
  echo "→ Création du dossier $SYMFONY_DIR pour les certificats Symfony..."
  mkdir -p "$SYMFONY_DIR"
fi

NETWORK_NAME=devcontainer-network
echo "Vérification du réseau Docker : $NETWORK_NAME"
if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
  echo "→ Réseau inexistant, création en cours..."
  docker network create "$NETWORK_NAME"
else
  echo "→ Réseau déjà existant, rien à faire."
fi