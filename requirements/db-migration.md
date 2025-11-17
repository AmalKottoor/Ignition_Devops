

- For db-migration, we use golang migrate 
- We need to make sure that when we do a rollback, we first do goto <version> before rollbacking, so our database stays good after a rollback.
- something like 

#!/bin/bash
set -e
DB_URL=$1
TARGET_DB_VERSION=$2

if [ -z "$DB_URL" ] || [ -z "$TARGET_VERSION" ]; then
  echo "Usage: rollback.sh <DB_URL> <target_db_version>"
  exit 1
fi

echo "Rolling back database to version $TARGET_VERSION..."
migrate -path ./migrations -database "$DB_URL" goto "$TARGET_DB_VERSION"

In CI/CD:
- name: Roll back DB
  run: ./scripts/rollback.sh ${{ secrets.PROD_DB_URL }} 10
