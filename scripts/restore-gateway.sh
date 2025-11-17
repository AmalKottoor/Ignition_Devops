#!/bin/bash
set -e

# Ignition Gateway Restore Script
# Usage: ./scripts/restore-gateway.sh <environment> <backup_file>
# Example: ./scripts/restore-gateway.sh dev ./backups/dev/gateway_backup_dev_20231201_120000.gwbk

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT=$1
BACKUP_FILE=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$BACKUP_FILE" ]; then
  echo "Error: Missing required arguments"
  echo "Usage: ./scripts/restore-gateway.sh <environment> <backup_file>"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file not found: $BACKUP_FILE"
  exit 1
fi

CONFIG_FILE="$PROJECT_ROOT/config/environments/${ENVIRONMENT}.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file not found: $CONFIG_FILE"
  exit 1
fi

# Parse configuration
GATEWAY_USER=$(grep "username:" "$CONFIG_FILE" | head -1 | awk '{print $2}')
GATEWAY_PASS=$(grep "password:" "$CONFIG_FILE" | head -1 | awk '{print $2}')
CONTAINER_NAME=$(grep "container_name:" "$CONFIG_FILE" | awk '{print $2}')

echo "=========================================="
echo "Restoring gateway backup for $ENVIRONMENT"
echo "=========================================="
echo "Backup file: $BACKUP_FILE"
echo ""

# Copy backup file to container
BACKUP_FILENAME=$(basename "$BACKUP_FILE")
docker cp "$BACKUP_FILE" "${CONTAINER_NAME}:/usr/local/bin/ignition/${BACKUP_FILENAME}"

# Restore using gwcmd
echo "Restoring backup inside container..."
docker exec "$CONTAINER_NAME" sh -c "
  cd /usr/local/bin/ignition
  ./gwcmd.sh --restore '$BACKUP_FILENAME' --username '$GATEWAY_USER' --password '$GATEWAY_PASS'
"

# Restart the container to apply changes
echo "Restarting container..."
docker restart "$CONTAINER_NAME"

# Wait for gateway to come back up
echo "Waiting for gateway to restart..."
sleep 30

echo ""
echo "✓ Restore completed successfully"
