#!/bin/bash
set -e

# Azure Pipelines Self-Hosted Agent Setup Script
# Supports macOS and Linux
# Usage: ./scripts/setup-agent.sh

echo "=========================================="
echo "Azure Pipelines Self-Hosted Agent Setup"
echo "=========================================="
echo ""

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Darwin*)
    OS_TYPE="osx"
    if [ "$ARCH" = "arm64" ]; then
      AGENT_FILE="vsts-agent-osx-arm64-3.246.0.tar.gz"
    else
      AGENT_FILE="vsts-agent-osx-x64-3.246.0.tar.gz"
    fi
    ;;
  Linux*)
    OS_TYPE="linux"
    AGENT_FILE="vsts-agent-linux-x64-3.246.0.tar.gz"
    ;;
  *)
    echo "Unsupported operating system: $OS"
    exit 1
    ;;
esac

echo "Detected: $OS_TYPE ($ARCH)"
echo ""

# Configuration
AGENT_DIR="$HOME/azure-agent"
AGENT_URL="https://vstsagentpackage.azureedge.net/agent/3.246.0/$AGENT_FILE"

# Prompt for configuration
echo "Please provide the following information:"
echo ""

read -p "Azure DevOps Organization URL [https://dev.azure.com/Wilms-ICT]: " ORG_URL
ORG_URL=${ORG_URL:-"https://dev.azure.com/Wilms-ICT"}

read -p "Agent Pool Name [CICD_AZ_INFRA_Agent]: " POOL_NAME
POOL_NAME=${POOL_NAME:-"CICD_AZ_INFRA_Agent"}

read -p "Agent Name [ignition-docker-agent-01]: " AGENT_NAME
AGENT_NAME=${AGENT_NAME:-"ignition-docker-agent-01"}

echo ""
echo "⚠️  You will need a Personal Access Token (PAT) with 'Agent Pools: Read & manage' scope."
echo "   Create one at: ${ORG_URL/_settings/tokens"
echo ""
read -sp "Personal Access Token (PAT): " PAT
echo ""
echo ""

# Create agent directory
echo "Step 1: Creating agent directory..."
mkdir -p "$AGENT_DIR"
cd "$AGENT_DIR"

# Download agent if not already present
if [ ! -f "$AGENT_FILE" ]; then
  echo "Step 2: Downloading agent..."
  if command -v curl &> /dev/null; then
    curl -L -O "$AGENT_URL"
  elif command -v wget &> /dev/null; then
    wget "$AGENT_URL"
  else
    echo "Error: Neither curl nor wget found. Please install one of them."
    exit 1
  fi
else
  echo "Step 2: Agent already downloaded, skipping..."
fi

# Extract agent if not already extracted
if [ ! -f "config.sh" ]; then
  echo "Step 3: Extracting agent..."
  tar zxf "$AGENT_FILE"
else
  echo "Step 3: Agent already extracted, skipping..."
fi

# Install dependencies on Linux
if [ "$OS_TYPE" = "linux" ]; then
  echo "Step 4: Installing dependencies..."
  if [ -f "bin/installdependencies.sh" ]; then
    sudo ./bin/installdependencies.sh
  fi
else
  echo "Step 4: Checking dependencies..."
  # Check Docker on macOS
  if ! command -v docker &> /dev/null; then
    echo "⚠️  Warning: Docker not found. Please install Docker Desktop for Mac."
  fi
fi

# Configure agent
echo "Step 5: Configuring agent..."
echo ""

# Create config file for unattended install
cat > .agent-config <<EOF
$ORG_URL
$PAT
$POOL_NAME
$AGENT_NAME
_work

EOF

# Run config with input from file
./config.sh --unattended \
  --url "$ORG_URL" \
  --auth pat \
  --token "$PAT" \
  --pool "$POOL_NAME" \
  --agent "$AGENT_NAME" \
  --acceptTeeEula \
  --work "_work" \
  --replace

# Remove config file with sensitive data
rm -f .agent-config

echo ""
echo "Step 6: Installing agent as service..."

if [ "$OS_TYPE" = "osx" ]; then
  ./svc.sh install
  ./svc.sh start
  echo ""
  echo "✓ Agent installed and started as macOS service"
  echo ""
  echo "Service commands:"
  echo "  Status:  cd $AGENT_DIR && ./svc.sh status"
  echo "  Stop:    cd $AGENT_DIR && ./svc.sh stop"
  echo "  Start:   cd $AGENT_DIR && ./svc.sh start"
  echo "  Logs:    cd $AGENT_DIR && ./svc.sh logs"
else
  sudo ./svc.sh install
  sudo ./svc.sh start
  echo ""
  echo "✓ Agent installed and started as Linux service"
  echo ""
  echo "Service commands:"
  echo "  Status:  cd $AGENT_DIR && sudo ./svc.sh status"
  echo "  Stop:    cd $AGENT_DIR && sudo ./svc.sh stop"
  echo "  Start:   cd $AGENT_DIR && sudo ./svc.sh start"
  echo "  Logs:    cd $AGENT_DIR && sudo ./svc.sh logs"
fi

echo ""
echo "=========================================="
echo "✓ Agent setup complete!"
echo "=========================================="
echo ""
echo "Agent Details:"
echo "  Name: $AGENT_NAME"
echo "  Pool: $POOL_NAME"
echo "  Location: $AGENT_DIR"
echo ""
echo "Next Steps:"
echo "1. Verify agent is online in Azure DevOps:"
echo "   $ORG_URL/_settings/agentpools?poolId=1&view=agents"
echo ""
echo "2. Ensure Docker containers are running:"
echo "   docker-compose ps"
echo ""
echo "3. Test the pipeline by pushing to develop branch:"
echo "   git checkout develop"
echo "   git commit --allow-empty -m 'Test self-hosted agent'"
echo "   git push origin develop"
echo ""
echo "For more information, see: SELF_HOSTED_AGENT_SETUP.md"
echo ""
