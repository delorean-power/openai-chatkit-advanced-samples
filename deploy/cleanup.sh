#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}========================================${NC}"
echo -e "${RED}ChatKit Cloud Run Cleanup${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${YELLOW}WARNING: This will delete all deployed resources!${NC}"
echo ""

# Load configuration
if [ -f .env.deploy ]; then
    source .env.deploy
else
    echo -e "${RED}Error: .env.deploy file not found${NC}"
    exit 1
fi

echo "Project: $GCP_PROJECT_ID"
echo "Region: $GCP_REGION"
echo ""
echo "This will delete:"
echo "  - Cloud Run services (backend and frontend)"
echo "  - Container images in Artifact Registry"
echo "  - Secrets in Secret Manager (optional)"
echo ""

read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

gcloud config set project $GCP_PROJECT_ID

# Delete Cloud Run services
echo ""
echo -e "${YELLOW}Deleting Cloud Run services...${NC}"

if gcloud run services describe $BACKEND_SERVICE_NAME --region=$GCP_REGION &> /dev/null; then
    gcloud run services delete $BACKEND_SERVICE_NAME \
        --region=$GCP_REGION \
        --quiet
    echo -e "${GREEN}✓ Backend service deleted${NC}"
else
    echo "Backend service not found"
fi

if gcloud run services describe $FRONTEND_SERVICE_NAME --region=$GCP_REGION &> /dev/null; then
    gcloud run services delete $FRONTEND_SERVICE_NAME \
        --region=$GCP_REGION \
        --quiet
    echo -e "${GREEN}✓ Frontend service deleted${NC}"
else
    echo "Frontend service not found"
fi

# Delete container images
echo ""
echo -e "${YELLOW}Deleting container images...${NC}"
read -p "Delete all images in Artifact Registry? (yes/no): " delete_images

if [ "$delete_images" == "yes" ]; then
    REPO_NAME="chatkit-images"
    
    # Delete backend images
    gcloud artifacts docker images delete \
        "$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/backend" \
        --quiet \
        --delete-tags 2>/dev/null || echo "No backend images found"
    
    # Delete frontend images
    gcloud artifacts docker images delete \
        "$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/frontend" \
        --quiet \
        --delete-tags 2>/dev/null || echo "No frontend images found"
    
    echo -e "${GREEN}✓ Container images deleted${NC}"
fi

# Delete secrets
echo ""
echo -e "${YELLOW}Deleting secrets...${NC}"
read -p "Delete secrets from Secret Manager? (yes/no): " delete_secrets

if [ "$delete_secrets" == "yes" ]; then
    gcloud secrets delete openai-api-key --quiet 2>/dev/null || echo "openai-api-key not found"
    gcloud secrets delete chatkit-domain-key --quiet 2>/dev/null || echo "chatkit-domain-key not found"
    gcloud secrets delete chatkit-workflow-id --quiet 2>/dev/null || echo "chatkit-workflow-id not found"
    echo -e "${GREEN}✓ Secrets deleted${NC}"
fi

# Delete Artifact Registry repository
echo ""
read -p "Delete entire Artifact Registry repository? (yes/no): " delete_repo

if [ "$delete_repo" == "yes" ]; then
    gcloud artifacts repositories delete chatkit-images \
        --location=$GCP_REGION \
        --quiet 2>/dev/null || echo "Repository not found"
    echo -e "${GREEN}✓ Artifact Registry repository deleted${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cleanup completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Note: This script does not:${NC}"
echo "  - Delete the GCP project"
echo "  - Disable APIs"
echo "  - Delete service accounts"
echo ""
echo "To completely remove all traces, you can:"
echo "  1. Disable the APIs manually"
echo "  2. Delete any remaining service accounts"
echo "  3. Review billing to ensure no charges"
echo ""
