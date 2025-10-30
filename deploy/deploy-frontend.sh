#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deploying Frontend to Cloud Run${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Load configuration
if [ -f .env.deploy ]; then
    source .env.deploy
else
    echo -e "${RED}Error: .env.deploy file not found${NC}"
    exit 1
fi

# Set GCP project
gcloud config set project $GCP_PROJECT_ID

# Get backend URL if not set
if [ -z "$BACKEND_URL" ]; then
    echo -e "${YELLOW}Fetching backend URL...${NC}"
    BACKEND_URL=$(gcloud run services describe $BACKEND_SERVICE_NAME \
        --region=$GCP_REGION \
        --format='value(status.url)')
    
    if [ -z "$BACKEND_URL" ]; then
        echo -e "${RED}Error: Could not find backend service${NC}"
        echo "Please deploy the backend first using ./deploy/deploy-backend.sh"
        exit 1
    fi
fi

echo -e "${YELLOW}Backend URL: $BACKEND_URL${NC}"

# Build and push Docker image
IMAGE_NAME="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/chatkit-images/frontend"
IMAGE_TAG="${IMAGE_TAG:-latest}"
FULL_IMAGE="$IMAGE_NAME:$IMAGE_TAG"

echo -e "${YELLOW}Building frontend Docker image...${NC}"
cd frontend

# Build with relative URLs (nginx will proxy to backend)
# The frontend uses /chatkit and /facts which nginx proxies to the backend
docker build \
    --build-arg VITE_CHATKIT_API_URL="/chatkit" \
    --build-arg VITE_FACTS_API_URL="/facts" \
    --build-arg VITE_CHATKIT_API_DOMAIN_KEY="${CHATKIT_DOMAIN_KEY:-}" \
    -t $FULL_IMAGE .

echo -e "${YELLOW}Pushing image to Artifact Registry...${NC}"
docker push $FULL_IMAGE

echo -e "${YELLOW}Deploying to Cloud Run...${NC}"
cd ..

# Deploy to Cloud Run with backend URL as environment variable
gcloud run deploy $FRONTEND_SERVICE_NAME \
    --image=$FULL_IMAGE \
    --region=$GCP_REGION \
    --platform=managed \
    --allow-unauthenticated \
    --set-env-vars="BACKEND_URL=$BACKEND_URL" \
    --memory=${FRONTEND_MEMORY:-256Mi} \
    --cpu=${FRONTEND_CPU:-1} \
    --min-instances=${FRONTEND_MIN_INSTANCES:-0} \
    --max-instances=${FRONTEND_MAX_INSTANCES:-10} \
    --timeout=${FRONTEND_TIMEOUT:-60} \
    --concurrency=${FRONTEND_CONCURRENCY:-80} \
    --port=8080

# Get the service URL
FRONTEND_URL=$(gcloud run services describe $FRONTEND_SERVICE_NAME \
    --region=$GCP_REGION \
    --format='value(status.url)')

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Frontend deployed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Frontend URL:${NC} $FRONTEND_URL"
echo -e "${YELLOW}Backend URL:${NC} $BACKEND_URL"
echo ""

# Check if custom domain is configured
if [ ! -z "$FRONTEND_CUSTOM_DOMAIN" ]; then
    echo -e "${YELLOW}Internal Domain Configuration:${NC}"
    echo "  Frontend: $FRONTEND_CUSTOM_DOMAIN"
    echo "  Backend:  ${BACKEND_CUSTOM_DOMAIN:-chatkit-api.lightshift.local}"
    echo ""
    echo -e "${YELLOW}To set up domain mapping, run:${NC}"
    echo "  ./deploy/setup-domain.sh"
    echo ""
fi

echo -e "${YELLOW}Important next steps:${NC}"
echo "1. Set up custom domain mapping (if not done):"
echo "   ./deploy/setup-domain.sh"
echo ""
echo "2. Add your domain to the ChatKit allowlist:"
echo "   https://platform.openai.com/settings/organization/security/domain-allowlist"
echo "   Domain: ${FRONTEND_CUSTOM_DOMAIN:-$FRONTEND_URL}"
echo ""
echo "3. Update .env.deploy with the CHATKIT_DOMAIN_KEY from the allowlist"
echo ""
echo "4. Redeploy the frontend with the domain key:"
echo "   ./deploy/deploy-frontend.sh"
echo ""
echo -e "${YELLOW}Test your deployment:${NC}"
echo "Cloud Run URL: $FRONTEND_URL"
if [ ! -z "$FRONTEND_CUSTOM_DOMAIN" ]; then
    echo "Internal URL:  https://$FRONTEND_CUSTOM_DOMAIN (after DNS setup)"
fi
echo ""
