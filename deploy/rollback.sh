#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load configuration
if [ -f .env.deploy ]; then
    source .env.deploy
else
    echo -e "${RED}Error: .env.deploy file not found${NC}"
    exit 1
fi

gcloud config set project $GCP_PROJECT_ID

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ChatKit Cloud Run Rollback${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Select service
echo -e "${YELLOW}Which service do you want to rollback?${NC}"
echo "1) Backend ($BACKEND_SERVICE_NAME)"
echo "2) Frontend ($FRONTEND_SERVICE_NAME)"
echo ""
read -p "Enter choice [1-2]: " choice

case $choice in
    1)
        SERVICE=$BACKEND_SERVICE_NAME
        ;;
    2)
        SERVICE=$FRONTEND_SERVICE_NAME
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# List revisions
echo -e "${YELLOW}Available revisions for $SERVICE:${NC}"
gcloud run revisions list \
    --service=$SERVICE \
    --region=$GCP_REGION \
    --format="table(metadata.name,status.conditions[0].status,metadata.creationTimestamp)" \
    --limit=10

echo ""
read -p "Enter revision name to rollback to: " REVISION

if [ -z "$REVISION" ]; then
    echo -e "${RED}No revision specified${NC}"
    exit 1
fi

# Confirm rollback
echo ""
echo -e "${YELLOW}You are about to rollback $SERVICE to revision: $REVISION${NC}"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Rollback cancelled"
    exit 0
fi

# Perform rollback
echo -e "${YELLOW}Rolling back...${NC}"
gcloud run services update-traffic $SERVICE \
    --region=$GCP_REGION \
    --to-revisions=$REVISION=100

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Rollback completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Service URL:${NC}"
gcloud run services describe $SERVICE \
    --region=$GCP_REGION \
    --format='value(status.url)'
echo ""
