#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deploying Backend to Cloud Run${NC}"
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

# Build and push Docker image
IMAGE_NAME="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/chatkit-images/backend"
IMAGE_TAG="${IMAGE_TAG:-latest}"
FULL_IMAGE="$IMAGE_NAME:$IMAGE_TAG"

echo -e "${YELLOW}Building backend Docker image...${NC}"
cd backend
docker build -t $FULL_IMAGE .

echo -e "${YELLOW}Pushing image to Artifact Registry...${NC}"
docker push $FULL_IMAGE

echo -e "${YELLOW}Deploying to Cloud Run...${NC}"
cd ..

# Deploy to Cloud Run
gcloud run deploy $BACKEND_SERVICE_NAME \
    --image=$FULL_IMAGE \
    --region=$GCP_REGION \
    --platform=managed \
    --allow-unauthenticated \
    --memory=${BACKEND_MEMORY:-512Mi} \
    --cpu=${BACKEND_CPU:-1} \
    --min-instances=${BACKEND_MIN_INSTANCES:-0} \
    --max-instances=${BACKEND_MAX_INSTANCES:-10} \
    --timeout=${BACKEND_TIMEOUT:-300} \
    --concurrency=${BACKEND_CONCURRENCY:-80} \
    --set-secrets="OPENAI_API_KEY=openai-api-key:latest" \
    --set-env-vars="ENVIRONMENT=production" \
    --port=8080

# Get the service URL
BACKEND_URL=$(gcloud run services describe $BACKEND_SERVICE_NAME \
    --region=$GCP_REGION \
    --format='value(status.url)')

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Backend deployed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Backend URL:${NC} $BACKEND_URL"
echo ""
echo -e "${YELLOW}Health check:${NC}"
curl -s "$BACKEND_URL/health" | jq '.' || echo "Health check endpoint: $BACKEND_URL/health"
echo ""
echo -e "${YELLOW}Save this URL for frontend deployment!${NC}"
echo ""
