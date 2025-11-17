#!/bin/bash
set -e

# Package Ignition Project
# Usage: ./scripts/package-project.sh <project_directory>
# Example: ./scripts/package-project.sh projects/my-project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR=$1

if [ -z "$PROJECT_DIR" ]; then
  echo "Error: Project directory not specified"
  echo "Usage: ./scripts/package-project.sh <project_directory>"
  exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: Project directory not found: $PROJECT_DIR"
  exit 1
fi

# Get project name from directory
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Get version from project.json if it exists
VERSION="1.0.0"
if [ -f "$PROJECT_DIR/project.json" ]; then
  VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_DIR/project.json" | cut -d'"' -f4 || echo "1.0.0")
fi

# Use git tag/commit for versioning if in git repo
if git rev-parse --git-dir > /dev/null 2>&1; then
  GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  GIT_COMMIT=$(git rev-parse --short HEAD)

  if [ -n "$GIT_TAG" ]; then
    VERSION="$GIT_TAG"
  else
    VERSION="${VERSION}-${GIT_COMMIT}"
  fi
fi

BUILD_DIR="$PROJECT_ROOT/build"
mkdir -p "$BUILD_DIR"

OUTPUT_FILE="$BUILD_DIR/${PROJECT_NAME}-${VERSION}.zip"

echo "=========================================="
echo "Packaging Ignition Project"
echo "=========================================="
echo "Project: $PROJECT_NAME"
echo "Version: $VERSION"
echo "Source: $PROJECT_DIR"
echo "Output: $OUTPUT_FILE"
echo ""

# Validate project structure
echo "Validating project structure..."
if [ ! -f "$PROJECT_DIR/project.json" ]; then
  echo "Warning: project.json not found in $PROJECT_DIR"
fi

# Package project (exclude temporary and local files)
echo "Creating package..."
cd "$PROJECT_DIR"
zip -r "$OUTPUT_FILE" . \
  -x "*.git*" \
  -x "*node_modules*" \
  -x "*__pycache__*" \
  -x "*.pyc" \
  -x "*/.DS_Store" \
  -x "*/var/*" \
  -x "*/local/*" \
  > /dev/null

cd "$PROJECT_ROOT"

echo "✓ Package created: $(basename "$OUTPUT_FILE")"
echo "  Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo ""
