#!/bin/bash

# Create the .symfony5 folder on the host if it doesn't exist (for HTTPS certificates)
SYMFONY_DIR="$HOME/.symfony5"
if [ ! -d "$SYMFONY_DIR" ]; then
  echo "→ Creating $SYMFONY_DIR folder for Symfony certificates..."
  mkdir -p "$SYMFONY_DIR"
fi

NETWORK_NAME=devcontainer-network
echo "Checking Docker network: $NETWORK_NAME"
if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
  echo "→ Network does not exist, creating..."
  docker network create "$NETWORK_NAME"
else
  echo "→ Network already exists, nothing to do."
fi