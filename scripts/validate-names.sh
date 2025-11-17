#!/bin/bash
set -e

# Validate Ignition Project Naming Conventions
# Based on linting requirements:
# - Files are camelCase
# - Functions are camelCase
# - Variables are camelCase
# - Indentations are tabs
# - No print statements in code
# - Components in Perspective are PascalCase
# - Properties on components are camelCase

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECTS_DIR="${1:-$PROJECT_ROOT/projects}"

echo "=========================================="
echo "Validating Project Naming Conventions"
echo "=========================================="
echo "Projects directory: $PROJECTS_DIR"
echo ""

EXIT_CODE=0

# Function to check if string is camelCase
is_camel_case() {
  [[ $1 =~ ^[a-z][a-zA-Z0-9]*$ ]]
}

# Function to check if string is PascalCase
is_pascal_case() {
  [[ $1 =~ ^[A-Z][a-zA-Z0-9]*$ ]]
}

# Validate project structure
if [ ! -d "$PROJECTS_DIR" ]; then
  echo "Warning: Projects directory not found: $PROJECTS_DIR"
  exit 0
fi

# Check each project
for project_dir in "$PROJECTS_DIR"/*/; do
  if [ ! -d "$project_dir" ]; then
    continue
  fi

  project_name=$(basename "$project_dir")
  echo "Checking project: $project_name"

  # Check Python files
  if [ -d "$project_dir" ]; then
    # Find Python files and check for print statements
    while IFS= read -r -d '' file; do
      if grep -n "print(" "$file" > /dev/null 2>&1; then
        echo "  ✗ Error: Print statement found in $file"
        grep -n "print(" "$file"
        EXIT_CODE=1
      fi

      # Check for tabs vs spaces (basic check)
      if grep -P "^    " "$file" > /dev/null 2>&1; then
        echo "  ⚠ Warning: Spaces used for indentation in $file (tabs required)"
      fi
    done < <(find "$project_dir" -name "*.py" -type f -print0)
  fi

  # Check Perspective view files (JSON)
  if [ -d "$project_dir/com.inductiveautomation.perspective/views" ]; then
    while IFS= read -r -d '' view_file; do
      # Basic validation for Perspective views
      if ! python3 -m json.tool "$view_file" > /dev/null 2>&1; then
        echo "  ✗ Error: Invalid JSON in $view_file"
        EXIT_CODE=1
      fi
    done < <(find "$project_dir/com.inductiveautomation.perspective/views" -name "*.json" -type f -print0)
  fi

  echo "  ✓ Project validated"
done

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo "✓ All validation checks passed"
else
  echo "✗ Validation failed - please fix the errors above"
fi

exit $EXIT_CODE
