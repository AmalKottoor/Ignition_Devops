#!/bin/bash
set -e

# Azure DevOps Pipeline Setup Helper
# This script helps set up the Azure DevOps pipeline variables and environments

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ORGANIZATION="Wilms-ICT"
PROJECT="poc_ignition_8.3"
REPO="poc_ignition_8.3"

echo "=========================================="
echo "Azure DevOps Pipeline Setup Helper"
echo "=========================================="
echo ""
echo "This script will help you set up the Azure DevOps pipeline."
echo ""
echo "Organization: $ORGANIZATION"
echo "Project: $PROJECT"
echo "Repository: $REPO"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed"
    echo "Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if DevOps extension is installed
if ! az extension list | grep -q "azure-devops"; then
    echo "Installing Azure DevOps extension..."
    az extension add --name azure-devops
fi

# Check if logged in
echo "Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure"
    echo "Please run: az login"
    exit 1
fi

echo "✓ Logged in to Azure"
echo ""

# Configure defaults
echo "Configuring Azure DevOps defaults..."
az devops configure --defaults organization=https://dev.azure.com/$ORGANIZATION project=$PROJECT

echo ""
echo "=========================================="
echo "Step 1: Create Environments"
echo "=========================================="
echo ""
echo "We need to create three environments:"
echo "  1. Development (auto-deploy from develop branch)"
echo "  2. Staging (auto-deploy from release/* branches)"
echo "  3. Production (manual approval required)"
echo ""
echo "NOTE: Environment creation via CLI may require additional permissions."
echo "If this fails, please create them manually in the Azure DevOps UI:"
echo "  → https://dev.azure.com/$ORGANIZATION/$PROJECT/_environments"
echo ""

read -p "Press Enter to attempt environment creation, or Ctrl+C to skip..."

# Try to create environments
for env in Development Staging Production; do
    echo "Creating environment: $env..."
    az pipelines environment create --name "$env" --project "$PROJECT" 2>/dev/null || echo "  ⚠ Could not create via CLI (may already exist or need manual creation)"
done

echo ""
echo "=========================================="
echo "Step 2: Create/Update Pipeline"
echo "=========================================="
echo ""
echo "Creating pipeline from azure-pipelines.yml..."

PIPELINE_NAME="Ignition 8.3 CI/CD"

# Check if pipeline exists
if az pipelines show --name "$PIPELINE_NAME" --project "$PROJECT" &> /dev/null; then
    echo "Pipeline '$PIPELINE_NAME' already exists"
else
    echo "Creating new pipeline..."
    # This requires additional permissions
    az pipelines create \
        --name "$PIPELINE_NAME" \
        --description "GitFlow CI/CD for Ignition 8.3 with multi-environment deployment" \
        --repository "$REPO" \
        --repository-type tfsgit \
        --branch main \
        --yml-path azure-pipelines.yml \
        --skip-first-run 2>/dev/null || echo "  ⚠ Could not create via CLI - please create manually in Azure DevOps UI"
fi

echo ""
echo "=========================================="
echo "Step 3: Configure Pipeline Variables"
echo "=========================================="
echo ""
echo "The following variables need to be added to your pipeline:"
echo ""
echo "VARIABLE NAME              | VALUE                        | SECRET?"
echo "---------------------------|------------------------------|--------"
echo "DEV_GATEWAY_URL            | http://localhost:8088        | No"
echo "DEV_GATEWAY_USER           | admin                        | No"
echo "DEV_GATEWAY_PASS           | dev-password                 | Yes"
echo "DEV_CONTAINER_NAME         | ignition-dev                 | No"
echo "STAGING_GATEWAY_URL        | http://localhost:8188        | No"
echo "STAGING_GATEWAY_USER       | admin                        | No"
echo "STAGING_GATEWAY_PASS       | staging-password             | Yes"
echo "STAGING_CONTAINER_NAME     | ignition-staging             | No"
echo "PROD_GATEWAY_URL           | http://localhost:8288        | No"
echo "PROD_GATEWAY_USER          | admin                        | No"
echo "PROD_GATEWAY_PASS          | prod-password                | Yes"
echo "PROD_CONTAINER_NAME        | ignition-prod                | No"
echo "DB_CONNECTION_STRING       | postgresql://ignition:...    | Yes"
echo ""
echo "NOTE: Pipeline variables must be added through the Azure DevOps UI"
echo "because they contain secrets and require proper access control."
echo ""
echo "To add these variables:"
echo "  1. Go to: https://dev.azure.com/$ORGANIZATION/$PROJECT/_build"
echo "  2. Click on your pipeline"
echo "  3. Click 'Edit'"
echo "  4. Click 'Variables' (top right)"
echo "  5. Add each variable above (mark passwords as 'Secret')"
echo ""

read -p "Press Enter when you've added all pipeline variables..."

echo ""
echo "=========================================="
echo "Step 4: Configure Branch Policies"
echo "=========================================="
echo ""
echo "To set up branch protection:"
echo "  1. Go to: https://dev.azure.com/$ORGANIZATION/$PROJECT/_settings/repositories?repo=$REPO&_a=policiesMid"
echo "  2. Click on 'main' branch"
echo "  3. Enable:"
echo "     - Require a minimum number of reviewers (1)"
echo "     - Build validation (select your pipeline)"
echo "  4. Repeat for 'develop' branch"
echo ""

read -p "Press Enter when you've configured branch policies..."

echo ""
echo "=========================================="
echo "Step 5: Add Production Approval"
echo "=========================================="
echo ""
echo "To require approval for production deployments:"
echo "  1. Go to: https://dev.azure.com/$ORGANIZATION/$PROJECT/_environments"
echo "  2. Click on 'Production' environment"
echo "  3. Click '...' → 'Approvals and checks'"
echo "  4. Click '+' → 'Approvals'"
echo "  5. Add yourself as an approver"
echo "  6. Click 'Create'"
echo ""

read -p "Press Enter when you've added production approval..."

echo ""
echo "=========================================="
echo "✓ Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Test the pipeline by pushing to develop:"
echo "   git checkout develop"
echo "   git push origin develop"
echo ""
echo "2. Monitor pipeline execution:"
echo "   https://dev.azure.com/$ORGANIZATION/$PROJECT/_build"
echo ""
echo "3. View deployed projects:"
echo "   - Dev:     http://localhost:8088/web/home"
echo "   - Staging: http://localhost:8188/web/home"
echo "   - Prod:    http://localhost:8288/web/home"
echo ""
echo "For detailed instructions, see: AZURE_PIPELINE_QUICKSTART.md"
echo ""
