#!/bin/bash
set -e

# Database Rollback Script
# Safely rolls back database to a specific version
# Usage: ./scripts/db-rollback.sh <environment> <target_version>
# Example: ./scripts/db-rollback.sh staging 10

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENT=$1
TARGET_VERSION=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$TARGET_VERSION" ]; then
  echo "Error: Missing required arguments"
  echo "Usage: ./scripts/db-rollback.sh <environment> <target_version>"
  exit 1
fi

echo "=========================================="
echo "Database Rollback"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Target Version: $TARGET_VERSION"
echo ""

# Get current version
echo "Current database version:"
"$SCRIPT_DIR/db-migrate.sh" "$ENVIRONMENT" version
echo ""

# Confirm rollback
read -p "Are you sure you want to rollback to version $TARGET_VERSION? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Rollback cancelled"
  exit 0
fi

# Perform rollback using goto to ensure database stays in good state
echo ""
echo "Rolling back to version $TARGET_VERSION..."
"$SCRIPT_DIR/db-migrate.sh" "$ENVIRONMENT" goto "$TARGET_VERSION"

echo ""
echo "✓ Rollback completed successfully"
echo ""
echo "New database version:"
"$SCRIPT_DIR/db-migrate.sh" "$ENVIRONMENT" version
