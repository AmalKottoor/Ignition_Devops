#!/bin/bash
set -e

# Deploy Individual Ignition Project
# Usage: ./scripts/deploy-project.sh <environment> <project_zip_file|project_directory>
# Example: ./scripts/deploy-project.sh dev ./build/my-project.zip
# Example: ./scripts/deploy-project.sh dev projects/TestProject

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT=$1
PROJECT_SOURCE=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$PROJECT_SOURCE" ]; then
  echo "Error: Missing required arguments"
  echo "Usage: ./scripts/deploy-project.sh <environment> <project_zip_file|project_directory>"
  exit 1
fi

# Check if source is zip file or directory
IS_ZIP=false
if [ -f "$PROJECT_SOURCE" ] && [[ "$PROJECT_SOURCE" == *.zip ]]; then
  IS_ZIP=true
elif [ ! -d "$PROJECT_SOURCE" ]; then
  echo "Error: Project source not found: $PROJECT_SOURCE"
  exit 1
fi

CONFIG_FILE="$PROJECT_ROOT/config/environments/${ENVIRONMENT}.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file not found: $CONFIG_FILE"
  exit 1
fi

# Parse configuration
CONTAINER_NAME=$(grep "container_name:" "$CONFIG_FILE" | awk '{print $2}')

# Determine project name and prepare source
if [ "$IS_ZIP" = true ]; then
  PROJECT_NAME=$(basename "$PROJECT_SOURCE" .zip)
  TEMP_DIR=$(mktemp -d)
  unzip -q "$PROJECT_SOURCE" -d "$TEMP_DIR"
  SOURCE_DIR="$TEMP_DIR"
else
  PROJECT_NAME=$(basename "$PROJECT_SOURCE")
  SOURCE_DIR="$PROJECT_SOURCE"
fi

echo "=========================================="
echo "Deploying Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "=========================================="

# Map environment to service directory
case "$ENVIRONMENT" in
  dev|development)
    ENV_DIR="ignition-dev"
    ;;
  staging)
    ENV_DIR="ignition-staging"
    ;;
  prod|production)
    ENV_DIR="ignition-prod"
    ;;
  *)
    echo "Error: Unknown environment: $ENVIRONMENT"
    exit 1
    ;;
esac

# Deploy to mounted directory (curated approach)
DEPLOY_DIR="$PROJECT_ROOT/services/$ENV_DIR/projects/$PROJECT_NAME"

echo "Deploying to: $DEPLOY_DIR"

# Create projects directory if it doesn't exist
mkdir -p "$(dirname "$DEPLOY_DIR")"

# Remove existing project if it exists
if [ -d "$DEPLOY_DIR" ]; then
  echo "Removing existing project..."
  rm -rf "$DEPLOY_DIR"
fi

# Copy project files
echo "Copying project files..."
cp -r "$SOURCE_DIR" "$DEPLOY_DIR"

# Clean up temp directory if we extracted a zip
if [ "$IS_ZIP" = true ]; then
  rm -rf "$TEMP_DIR"
fi

# Restart container to reload project
echo "Restarting gateway to load project..."
docker restart "$CONTAINER_NAME" > /dev/null

echo ""
echo "✓ Project deployed successfully!"
echo "  Project: $PROJECT_NAME"
echo "  Environment: $ENVIRONMENT ($ENV_DIR)"
echo "  Location: services/$ENV_DIR/projects/$PROJECT_NAME"
echo ""
echo "Gateway is restarting... wait ~30 seconds then access:"
case "$ENVIRONMENT" in
  dev|development)
    echo "  http://localhost:8088/web/home"
    ;;
  staging)
    echo "  http://localhost:8188/web/home"
    ;;
  prod|production)
    echo "  http://localhost:8288/web/home"
    ;;
esac
echo ""
