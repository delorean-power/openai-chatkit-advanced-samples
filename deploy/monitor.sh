#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
echo -e "${GREEN}ChatKit Cloud Run Monitoring${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to display service status
show_service_status() {
    local service=$1
    local service_name=$2
    
    echo -e "${BLUE}$service_name Status:${NC}"
    
    # Get service details
    STATUS=$(gcloud run services describe $service \
        --region=$GCP_REGION \
        --format='value(status.conditions[0].status)' 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$STATUS" == "NOT_FOUND" ]; then
        echo -e "${RED}  Service not deployed${NC}"
        return
    fi
    
    URL=$(gcloud run services describe $service \
        --region=$GCP_REGION \
        --format='value(status.url)')
    
    REVISION=$(gcloud run services describe $service \
        --region=$GCP_REGION \
        --format='value(status.latestReadyRevisionName)')
    
    echo -e "  Status: ${GREEN}$STATUS${NC}"
    echo -e "  URL: $URL"
    echo -e "  Latest Revision: $REVISION"
    
    # Test health endpoint
    if [ "$service" == "$BACKEND_SERVICE_NAME" ]; then
        echo -e "  ${YELLOW}Testing health endpoint...${NC}"
        HEALTH=$(curl -s -w "\n%{http_code}" "$URL/health" 2>/dev/null)
        HTTP_CODE=$(echo "$HEALTH" | tail -n1)
        RESPONSE=$(echo "$HEALTH" | head -n-1)
        
        if [ "$HTTP_CODE" == "200" ]; then
            echo -e "  Health Check: ${GREEN}✓ Healthy${NC}"
            echo "  Response: $RESPONSE"
        else
            echo -e "  Health Check: ${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
        fi
    fi
    echo ""
}

# Show service statuses
show_service_status "$BACKEND_SERVICE_NAME" "Backend"
show_service_status "$FRONTEND_SERVICE_NAME" "Frontend"

# Show recent logs option
echo -e "${YELLOW}Recent Logs:${NC}"
echo "Backend:  gcloud run services logs read $BACKEND_SERVICE_NAME --region=$GCP_REGION --limit=50"
echo "Frontend: gcloud run services logs read $FRONTEND_SERVICE_NAME --region=$GCP_REGION --limit=50"
echo ""

# Show metrics option
echo -e "${YELLOW}View Metrics:${NC}"
echo "https://console.cloud.google.com/run/detail/$GCP_REGION/$BACKEND_SERVICE_NAME/metrics?project=$GCP_PROJECT_ID"
echo "https://console.cloud.google.com/run/detail/$GCP_REGION/$FRONTEND_SERVICE_NAME/metrics?project=$GCP_PROJECT_ID"
echo ""

# Interactive menu
echo -e "${YELLOW}What would you like to do?${NC}"
echo "1) View backend logs (live)"
echo "2) View frontend logs (live)"
echo "3) View backend metrics"
echo "4) View frontend metrics"
echo "5) Restart backend"
echo "6) Restart frontend"
echo "7) Exit"
echo ""

read -p "Enter choice [1-7]: " choice

case $choice in
    1)
        echo -e "${YELLOW}Streaming backend logs (Ctrl+C to exit)...${NC}"
        gcloud run services logs tail $BACKEND_SERVICE_NAME --region=$GCP_REGION
        ;;
    2)
        echo -e "${YELLOW}Streaming frontend logs (Ctrl+C to exit)...${NC}"
        gcloud run services logs tail $FRONTEND_SERVICE_NAME --region=$GCP_REGION
        ;;
    3)
        open "https://console.cloud.google.com/run/detail/$GCP_REGION/$BACKEND_SERVICE_NAME/metrics?project=$GCP_PROJECT_ID"
        ;;
    4)
        open "https://console.cloud.google.com/run/detail/$GCP_REGION/$FRONTEND_SERVICE_NAME/metrics?project=$GCP_PROJECT_ID"
        ;;
    5)
        echo -e "${YELLOW}Restarting backend...${NC}"
        gcloud run services update $BACKEND_SERVICE_NAME --region=$GCP_REGION --update-env-vars="RESTART_TIME=$(date +%s)"
        echo -e "${GREEN}Backend restarted${NC}"
        ;;
    6)
        echo -e "${YELLOW}Restarting frontend...${NC}"
        gcloud run services update $FRONTEND_SERVICE_NAME --region=$GCP_REGION --update-env-vars="RESTART_TIME=$(date +%s)"
        echo -e "${GREEN}Frontend restarted${NC}"
        ;;
    7)
        echo "Goodbye!"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        ;;
esac
