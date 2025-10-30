#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OpenAI ChatKit Cloud Run Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Load configuration
if [ -f .env.deploy ]; then
    source .env.deploy
else
    echo -e "${RED}Error: .env.deploy file not found${NC}"
    echo "Please create .env.deploy from .env.deploy.template"
    exit 1
fi

# Validate required variables
REQUIRED_VARS=(
    "GCP_PROJECT_ID"
    "GCP_REGION"
    "BACKEND_SERVICE_NAME"
    "FRONTEND_SERVICE_NAME"
    "OPENAI_API_KEY"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}Error: $var is not set in .env.deploy${NC}"
        exit 1
    fi
done

echo -e "${YELLOW}Configuration:${NC}"
echo "  Project ID: $GCP_PROJECT_ID"
echo "  Region: $GCP_REGION"
echo "  Backend Service: $BACKEND_SERVICE_NAME"
echo "  Frontend Service: $FRONTEND_SERVICE_NAME"
echo ""

# Set GCP project
echo -e "${YELLOW}Setting GCP project...${NC}"
gcloud config set project $GCP_PROJECT_ID

# Enable required APIs
echo -e "${YELLOW}Enabling required GCP APIs...${NC}"
gcloud services enable \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    secretmanager.googleapis.com \
    logging.googleapis.com \
    monitoring.googleapis.com

# Create Artifact Registry repository if it doesn't exist
echo -e "${YELLOW}Setting up Artifact Registry...${NC}"
REPO_NAME="chatkit-images"
if ! gcloud artifacts repositories describe $REPO_NAME --location=$GCP_REGION &> /dev/null; then
    gcloud artifacts repositories create $REPO_NAME \
        --repository-format=docker \
        --location=$GCP_REGION \
        --description="ChatKit application images"
    echo -e "${GREEN}✓ Artifact Registry repository created${NC}"
else
    echo -e "${GREEN}✓ Artifact Registry repository already exists${NC}"
fi

# Create Secret Manager secrets
echo -e "${YELLOW}Setting up Secret Manager...${NC}"

# OpenAI API Key
if ! gcloud secrets describe openai-api-key &> /dev/null; then
    echo -n "$OPENAI_API_KEY" | gcloud secrets create openai-api-key \
        --data-file=- \
        --replication-policy="automatic"
    echo -e "${GREEN}✓ OpenAI API key secret created${NC}"
else
    echo -e "${GREEN}✓ OpenAI API key secret already exists${NC}"
fi

# ChatKit Domain Key (if provided)
if [ ! -z "$CHATKIT_DOMAIN_KEY" ]; then
    if ! gcloud secrets describe chatkit-domain-key &> /dev/null; then
        echo -n "$CHATKIT_DOMAIN_KEY" | gcloud secrets create chatkit-domain-key \
            --data-file=- \
            --replication-policy="automatic"
        echo -e "${GREEN}✓ ChatKit domain key secret created${NC}"
    else
        echo -e "${GREEN}✓ ChatKit domain key secret already exists${NC}"
    fi
fi

# Workflow ID (if provided)
if [ ! -z "$CHATKIT_WORKFLOW_ID" ]; then
    if ! gcloud secrets describe chatkit-workflow-id &> /dev/null; then
        echo -n "$CHATKIT_WORKFLOW_ID" | gcloud secrets create chatkit-workflow-id \
            --data-file=- \
            --replication-policy="automatic"
        echo -e "${GREEN}✓ ChatKit workflow ID secret created${NC}"
    else
        echo -e "${GREEN}✓ ChatKit workflow ID secret already exists${NC}"
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run ./deploy/deploy-backend.sh to deploy the backend"
echo "2. Run ./deploy/deploy-frontend.sh to deploy the frontend"
echo "3. Configure your domain allowlist at:"
echo "   https://platform.openai.com/settings/organization/security/domain-allowlist"
echo ""
