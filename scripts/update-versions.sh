#!/bin/bash

# Script to update .devcontainer/.env and Dockerfiles from .versions.json

VERSIONS_FILE=".versions.json"
ENV_FILE=".devcontainer/.env"

# Dockerfiles to update
DOCKERFILES=(
  ".devcontainer/Dockerfile.dev"
  ".devcontainer/Dockerfile.apache.prod"
  ".devcontainer/Dockerfile.node.prod"
  ".devcontainer/Dockerfile.spa.prod"
)

# Check if .versions.json exists
if [ ! -f "$VERSIONS_FILE" ]; then
  echo "❌ Error: $VERSIONS_FILE not found"
  exit 1
fi

# Extract versions from .versions.json using grep
PHP_VERSION=$(grep '"php"' "$VERSIONS_FILE" | grep -oP ':\s*"\K[^"]+')
NODE_VERSION=$(grep '"node"' "$VERSIONS_FILE" | grep -oP ':\s*"\K[^"]+')
DB_IMAGE=$(grep '"db_image"' "$VERSIONS_FILE" | grep -oP ':\s*"\K[^"]+')

# Check if versions were extracted
if [ -z "$PHP_VERSION" ] || [ -z "$NODE_VERSION" ] || [ -z "$DB_IMAGE" ]; then
  echo "❌ Error: Could not read versions from $VERSIONS_FILE"
  exit 1
fi

# Update .env file
sed -i.bak "s/^PHP_VERSION=.*/PHP_VERSION=$PHP_VERSION/" "$ENV_FILE"
sed -i.bak "s/^NODE_VERSION=.*/NODE_VERSION=$NODE_VERSION/" "$ENV_FILE"
sed -i.bak "s/^DB_IMAGE=.*/DB_IMAGE=$DB_IMAGE/" "$ENV_FILE"
sed -i.bak "s/^DEV_IMAGE=.*/DEV_IMAGE=symfony-devcontainer-template-image:php$PHP_VERSION-node$NODE_VERSION/" "$ENV_FILE"
rm -f "${ENV_FILE}.bak"

# Update Dockerfiles
for dockerfile in "${DOCKERFILES[@]}"; do
  if [ -f "$dockerfile" ]; then
    # Update PHP_VERSION ARG if present
    sed -i.bak "s/^ARG PHP_VERSION=.*/ARG PHP_VERSION=$PHP_VERSION/" "$dockerfile"

    # Update NODE_VERSION ARG
    sed -i.bak "s/^ARG NODE_VERSION=.*/ARG NODE_VERSION=$NODE_VERSION/" "$dockerfile"

    rm -f "${dockerfile}.bak"
  fi
done

echo "✅ Versions updated from .versions.json:"
echo "   PHP: $PHP_VERSION"
echo "   Node: $NODE_VERSION"
echo "   DB Image: $DB_IMAGE"
echo "   DEV_IMAGE: symfony-devcontainer-template-image:php$PHP_VERSION-node$NODE_VERSION"
echo ""
echo "Updated files:"
echo "   ✓ .devcontainer/.env"
for dockerfile in "${DOCKERFILES[@]}"; do
  if [ -f "$dockerfile" ]; then
    echo "   ✓ $dockerfile"
  fi
done
