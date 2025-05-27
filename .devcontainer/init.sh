#!/bin/bash

[ "$DEBUG" == "1" ] && set -x

NETWORK_NAME=devcontainer-network
echo "Vérification du réseau Docker : $NETWORK_NAME"
if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
  echo "→ Réseau inexistant, création en cours..."
  docker network create "$NETWORK_NAME"
else
  echo "→ Réseau déjà existant, rien à faire."
fi