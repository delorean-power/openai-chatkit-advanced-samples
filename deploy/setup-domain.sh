#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ChatKit Domain Mapping Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Load configuration
if [ -f .env.deploy ]; then
    source .env.deploy
else
    echo -e "${RED}Error: .env.deploy file not found${NC}"
    exit 1
fi

# Set defaults if not provided
BACKEND_CUSTOM_DOMAIN=${BACKEND_CUSTOM_DOMAIN:-chatkit-api.lightshift.local}
FRONTEND_CUSTOM_DOMAIN=${FRONTEND_CUSTOM_DOMAIN:-chatkit.lightshift.local}

echo -e "${YELLOW}Configuration:${NC}"
echo "  Project ID: $GCP_PROJECT_ID"
echo "  Region: $GCP_REGION"
echo "  Backend Domain: $BACKEND_CUSTOM_DOMAIN"
echo "  Frontend Domain: $FRONTEND_CUSTOM_DOMAIN"
echo ""

gcloud config set project $GCP_PROJECT_ID

# Map backend domain
echo -e "${YELLOW}Setting up backend domain mapping...${NC}"
if gcloud beta run domain-mappings describe --domain=$BACKEND_CUSTOM_DOMAIN --region=$GCP_REGION &> /dev/null; then
    echo -e "${YELLOW}Backend domain mapping already exists, updating...${NC}"
    gcloud run services update-traffic $BACKEND_SERVICE_NAME \
        --region=$GCP_REGION \
        --to-latest
else
    echo -e "${YELLOW}Creating backend domain mapping...${NC}"
    gcloud beta run domain-mappings create \
        --service=$BACKEND_SERVICE_NAME \
        --domain=$BACKEND_CUSTOM_DOMAIN \
        --region=$GCP_REGION
fi

# Map frontend domain
echo -e "${YELLOW}Setting up frontend domain mapping...${NC}"
if gcloud beta run domain-mappings describe --domain=$FRONTEND_CUSTOM_DOMAIN --region=$GCP_REGION &> /dev/null; then
    echo -e "${YELLOW}Frontend domain mapping already exists, updating...${NC}"
    gcloud run services update-traffic $FRONTEND_SERVICE_NAME \
        --region=$GCP_REGION \
        --to-latest
else
    echo -e "${YELLOW}Creating frontend domain mapping...${NC}"
    gcloud beta run domain-mappings create \
        --service=$FRONTEND_SERVICE_NAME \
        --domain=$FRONTEND_CUSTOM_DOMAIN \
        --region=$GCP_REGION
fi

# Get DNS records
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Domain Mapping Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}DNS Configuration Required:${NC}"
echo ""

echo -e "${YELLOW}Backend ($BACKEND_CUSTOM_DOMAIN):${NC}"
gcloud beta run domain-mappings describe --domain=$BACKEND_CUSTOM_DOMAIN --region=$GCP_REGION \
    --format="table(status.resourceRecords.name,status.resourceRecords.type,status.resourceRecords.rrdata)" 2>/dev/null || \
    echo "Run this command to get DNS records:"
echo "  gcloud beta run domain-mappings describe --domain=$BACKEND_CUSTOM_DOMAIN --region=$GCP_REGION"
echo ""

echo -e "${YELLOW}Frontend ($FRONTEND_CUSTOM_DOMAIN):${NC}"
gcloud beta run domain-mappings describe --domain=$FRONTEND_CUSTOM_DOMAIN --region=$GCP_REGION \
    --format="table(status.resourceRecords.name,status.resourceRecords.type,status.resourceRecords.rrdata)" 2>/dev/null || \
    echo "Run this command to get DNS records:"
echo "  gcloud beta run domain-mappings describe --domain=$FRONTEND_CUSTOM_DOMAIN --region=$GCP_REGION"
echo ""

echo -e "${YELLOW}Add these DNS records to your lightshift.local DNS configuration${NC}"
echo ""
echo -e "${YELLOW}After DNS propagation, your services will be available at:${NC}"
echo "  Frontend: https://$FRONTEND_CUSTOM_DOMAIN"
echo "  Backend:  https://$BACKEND_CUSTOM_DOMAIN"
echo ""
echo -e "${YELLOW}Don't forget to update ChatKit domain allowlist:${NC}"
echo "  https://platform.openai.com/settings/organization/security/domain-allowlist"
echo "  Add: $FRONTEND_CUSTOM_DOMAIN"
echo ""
