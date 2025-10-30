#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ChatKit Cloud Run Setup Verification${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if deployment scripts exist
echo -e "${YELLOW}Checking deployment files...${NC}"

FILES=(
    "deploy/setup.sh"
    "deploy/deploy-backend.sh"
    "deploy/deploy-frontend.sh"
    "deploy/deploy-all.sh"
    "deploy/monitor.sh"
    "deploy/rollback.sh"
    "deploy/cleanup.sh"
    "deploy/local-test.sh"
    ".env.deploy.template"
    "backend/Dockerfile"
    "frontend/Dockerfile"
    "frontend/nginx.conf"
)

MISSING=0
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file (missing)"
        MISSING=$((MISSING + 1))
    fi
done

echo ""

if [ $MISSING -gt 0 ]; then
    echo -e "${RED}Error: $MISSING files are missing${NC}"
    exit 1
fi

# Check if scripts are executable
echo -e "${YELLOW}Checking script permissions...${NC}"

SCRIPTS=(
    "deploy/setup.sh"
    "deploy/deploy-backend.sh"
    "deploy/deploy-frontend.sh"
    "deploy/deploy-all.sh"
    "deploy/monitor.sh"
    "deploy/rollback.sh"
    "deploy/cleanup.sh"
    "deploy/local-test.sh"
)

NON_EXEC=0
for script in "${SCRIPTS[@]}"; do
    if [ -x "$script" ]; then
        echo -e "${GREEN}✓${NC} $script is executable"
    else
        echo -e "${YELLOW}⚠${NC} $script is not executable (run: chmod +x deploy/*.sh)"
        NON_EXEC=$((NON_EXEC + 1))
    fi
done

echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check gcloud
if command -v gcloud &> /dev/null; then
    echo -e "${GREEN}✓${NC} gcloud CLI installed"
    GCLOUD_VERSION=$(gcloud version --format="value(core)" 2>/dev/null)
    echo "  Version: $GCLOUD_VERSION"
else
    echo -e "${RED}✗${NC} gcloud CLI not installed"
    echo "  Install from: https://cloud.google.com/sdk/docs/install"
fi

# Check Docker
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker installed"
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | tr -d ',')
    echo "  Version: $DOCKER_VERSION"
    
    # Check if Docker is running
    if docker info &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker daemon is running"
    else
        echo -e "${RED}✗${NC} Docker daemon is not running"
    fi
else
    echo -e "${RED}✗${NC} Docker not installed"
    echo "  Install from: https://docs.docker.com/get-docker/"
fi

# Check for .env.deploy
echo ""
echo -e "${YELLOW}Checking configuration...${NC}"

if [ -f ".env.deploy" ]; then
    echo -e "${GREEN}✓${NC} .env.deploy exists"
    
    # Check required variables
    source .env.deploy 2>/dev/null
    
    if [ -n "$GCP_PROJECT_ID" ]; then
        echo -e "${GREEN}✓${NC} GCP_PROJECT_ID is set: $GCP_PROJECT_ID"
    else
        echo -e "${RED}✗${NC} GCP_PROJECT_ID not set in .env.deploy"
    fi
    
    if [ -n "$OPENAI_API_KEY" ]; then
        echo -e "${GREEN}✓${NC} OPENAI_API_KEY is set"
    else
        echo -e "${RED}✗${NC} OPENAI_API_KEY not set in .env.deploy"
    fi
else
    echo -e "${YELLOW}⚠${NC} .env.deploy not found"
    echo "  Create from template: cp .env.deploy.template .env.deploy"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Verification Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ $NON_EXEC -gt 0 ]; then
    echo -e "${YELLOW}Next step: Make scripts executable${NC}"
    echo "  chmod +x deploy/*.sh"
    echo ""
fi

if [ ! -f ".env.deploy" ]; then
    echo -e "${YELLOW}Next step: Configure deployment${NC}"
    echo "  cp .env.deploy.template .env.deploy"
    echo "  # Edit .env.deploy with your values"
    echo ""
fi

echo -e "${YELLOW}Ready to deploy?${NC}"
echo "  1. Ensure all prerequisites are installed"
echo "  2. Configure .env.deploy"
echo "  3. Run: ./deploy/deploy-all.sh"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo "  - QUICKSTART.md - 5-minute deployment guide"
echo "  - CLOUD_RUN_DEPLOYMENT.md - Complete documentation"
echo "  - CUSTOM_AGENTS.md - Custom agents guide"
echo ""
