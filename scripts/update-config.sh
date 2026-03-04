#!/bin/bash

# Script to update .devcontainer/.env and Dockerfiles from .config.json

CONFIG_FILE=".config.json"
ENV_FILE=".devcontainer/.env"
DEVCONTAINER_FILE=".devcontainer/devcontainer.json"
COMPOSE_DEV_FILE=".devcontainer/docker-compose.dev.yml"
LAUNCH_FILE=".vscode/launch.json"
WORKSPACE_FILE="project.code-workspace"
BACKEND_WORKSPACE_FILE="backend.code-workspace"

# Dockerfiles to update
DOCKERFILES=(
  ".devcontainer/Dockerfile.dev"
  ".devcontainer/Dockerfile.apache.prod"
  ".devcontainer/Dockerfile.node.prod"
  ".devcontainer/Dockerfile.spa.prod"
)

# Check if .config.json exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: $CONFIG_FILE not found"
  exit 1
fi

# Extract values from .config.json using grep
PROJECT_NAME=$(grep '"project_name"' "$CONFIG_FILE" | grep -oP ':\s*"\K[^"]+')
PHP_VERSION=$(grep '"php"' "$CONFIG_FILE" | grep -oP ':\s*"\K[^"]+')
NODE_VERSION=$(grep '"node"' "$CONFIG_FILE" | grep -oP ':\s*"\K[^"]+')
DB_IMAGE=$(grep '"db_image"' "$CONFIG_FILE" | grep -oP ':\s*"\K[^"]+')
SERVER_VERSION=$(grep '"server_version"' "$CONFIG_FILE" | grep -oP ':\s*"\K[^"]+')
REDIS_IMAGE=$(grep '"redis_image"' "$CONFIG_FILE" | grep -oP ':\s*"\K[^"]+')
ADMINER_IMAGE=$(grep '"adminer_image"' "$CONFIG_FILE" | grep -oP ':\s*"\K[^"]+')
FRONTEND_PORT=$(grep '"frontend_localhost_port"' "$CONFIG_FILE" | grep -oP ':\s*"\K[^"]+')

# Check if required values were extracted
if [ -z "$PROJECT_NAME" ] || [ -z "$PHP_VERSION" ] || [ -z "$NODE_VERSION" ] || [ -z "$DB_IMAGE" ]; then
  echo "❌ Error: Could not read required values from $CONFIG_FILE"
  exit 1
fi

# Validate values to prevent sed corruption
if ! echo "$PROJECT_NAME" | grep -qE '^[a-z0-9][a-z0-9-]*$'; then
  echo "❌ Error: project_name must contain only lowercase letters, numbers, and hyphens (e.g. 'my-project')"
  exit 1
fi
if ! echo "$PHP_VERSION" | grep -qE '^[0-9]+(\.[0-9]+)*$'; then
  echo "❌ Error: php version must be a number (e.g. '8.3')"
  exit 1
fi
if ! echo "$NODE_VERSION" | grep -qE '^[0-9]+(\.[0-9]+)*$'; then
  echo "❌ Error: node version must be a number (e.g. '22')"
  exit 1
fi
if ! echo "$FRONTEND_PORT" | grep -qE '^[0-9]+$'; then
  echo "❌ Error: frontend_localhost_port must be a number (e.g. '5173')"
  exit 1
fi

# Update .env file
sed -i.bak "s/^PROJECT_NAME=.*/PROJECT_NAME=$PROJECT_NAME/" "$ENV_FILE"
sed -i.bak "s/^PHP_VERSION=.*/PHP_VERSION=$PHP_VERSION/" "$ENV_FILE"
sed -i.bak "s/^NODE_VERSION=.*/NODE_VERSION=$NODE_VERSION/" "$ENV_FILE"
sed -i.bak "s/^DB_IMAGE=.*/DB_IMAGE=$DB_IMAGE/" "$ENV_FILE"
if [ -n "$SERVER_VERSION" ]; then
  sed -i.bak "s/^SERVER_VERSION=.*\(#.*\)$/SERVER_VERSION=$SERVER_VERSION \1/" "$ENV_FILE"
fi
sed -i.bak "s/^DEV_IMAGE=.*/DEV_IMAGE=symfony-devcontainer-template-image:php$PHP_VERSION-node$NODE_VERSION/" "$ENV_FILE"
if [ -n "$REDIS_IMAGE" ]; then
  sed -i.bak "s/^REDIS_IMAGE=.*/REDIS_IMAGE=$REDIS_IMAGE/" "$ENV_FILE"
fi
if [ -n "$ADMINER_IMAGE" ]; then
  sed -i.bak "s/^ADMINER_IMAGE=.*/ADMINER_IMAGE=$ADMINER_IMAGE/" "$ENV_FILE"
fi
if [ -n "$FRONTEND_PORT" ]; then
  sed -i.bak "s/^FRONTEND_LOCALHOST_PORT=.*/FRONTEND_LOCALHOST_PORT=$FRONTEND_PORT/" "$ENV_FILE"
fi
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

# Update devcontainer.json
if [ -f "$DEVCONTAINER_FILE" ]; then
  sed -i.bak "s/\"intelephense.environment.phpVersion\": \"[^\"]*\"/\"intelephense.environment.phpVersion\": \"$PHP_VERSION\"/" "$DEVCONTAINER_FILE"
  sed -i.bak "s|\"workspaceFolder\": \"[^\"]*\"|\"workspaceFolder\": \"/workspace-$PROJECT_NAME\"|" "$DEVCONTAINER_FILE"
  rm -f "${DEVCONTAINER_FILE}.bak"
fi

# Update launch.json Xdebug pathMappings
if [ -f "$LAUNCH_FILE" ]; then
  sed -i.bak "/workspaceFolder/s|\"/workspace[^\"]*\"|\"/workspace-${PROJECT_NAME}\"|" "$LAUNCH_FILE"
  rm -f "${LAUNCH_FILE}.bak"
fi

# Update project.code-workspace Xdebug pathMappings
if [ -f "$WORKSPACE_FILE" ]; then
  sed -i.bak "s|\"/workspace[^\"]*\/backend\"|\"/workspace-${PROJECT_NAME}/backend\"|" "$WORKSPACE_FILE"
  rm -f "${WORKSPACE_FILE}.bak"
fi

# Update backend.code-workspace Xdebug pathMappings
if [ -f "$BACKEND_WORKSPACE_FILE" ]; then
  sed -i.bak "s|\"/workspace[^\"]*\/backend\"|\"/workspace-${PROJECT_NAME}/backend\"|" "$BACKEND_WORKSPACE_FILE"
  rm -f "${BACKEND_WORKSPACE_FILE}.bak"
fi

echo "✅ Config updated from .config.json:"
echo "   Project: $PROJECT_NAME"
echo "   PHP: $PHP_VERSION"
echo "   Node: $NODE_VERSION"
echo "   DB Image: $DB_IMAGE"
echo "   Server Version: $SERVER_VERSION"
echo "   Redis Image: $REDIS_IMAGE"
echo "   Adminer Image: $ADMINER_IMAGE"
echo "   Frontend Port: $FRONTEND_PORT"
echo "   DEV_IMAGE: symfony-devcontainer-template-image:php$PHP_VERSION-node$NODE_VERSION"
echo ""
echo "Updated files:"
echo "   ✓ .devcontainer/.env (PROJECT_NAME + versions + frontend port)"
echo "   ✓ .devcontainer/devcontainer.json (workspaceFolder + Intelephense)"
echo "   ✓ .vscode/launch.json (Xdebug pathMappings)"
echo "   ✓ project.code-workspace (Xdebug pathMappings)"
echo "   ✓ backend.code-workspace (Xdebug pathMappings)"
for dockerfile in "${DOCKERFILES[@]}"; do
  if [ -f "$dockerfile" ]; then
    echo "   ✓ $dockerfile"
  fi
done
