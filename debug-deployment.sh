#!/bin/bash

# Debug script to check deployment status

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ChatKit Deployment Debug${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Load environment
if [ -f .env.deploy ]; then
    source .env.deploy
else
    echo -e "${RED}Error: .env.deploy not found${NC}"
    exit 1
fi

GCP_REGION=${GCP_REGION:-us-central1}

echo -e "${YELLOW}1. Checking Backend Service...${NC}"
BACKEND_URL=$(gcloud run services describe chatkit-backend \
    --region=$GCP_REGION \
    --format='value(status.url)' 2>/dev/null || echo "NOT_FOUND")

if [ "$BACKEND_URL" = "NOT_FOUND" ]; then
    echo -e "${RED}❌ Backend service not found${NC}"
else
    echo -e "${GREEN}✅ Backend URL: $BACKEND_URL${NC}"
    
    # Test backend health
    echo -e "${YELLOW}   Testing backend health...${NC}"
    HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/health" || echo "000")
    if [ "$HEALTH_RESPONSE" = "200" ]; then
        echo -e "${GREEN}   ✅ Backend health check: OK${NC}"
    else
        echo -e "${RED}   ❌ Backend health check failed: HTTP $HEALTH_RESPONSE${NC}"
    fi
    
    # Test backend /chatkit endpoint
    echo -e "${YELLOW}   Testing backend /chatkit endpoint...${NC}"
    CHATKIT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS "$BACKEND_URL/chatkit" || echo "000")
    if [ "$CHATKIT_RESPONSE" = "200" ]; then
        echo -e "${GREEN}   ✅ Backend /chatkit OPTIONS: OK${NC}"
    else
        echo -e "${RED}   ❌ Backend /chatkit OPTIONS failed: HTTP $CHATKIT_RESPONSE${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}2. Checking Frontend Service...${NC}"
FRONTEND_URL=$(gcloud run services describe chatkit-frontend \
    --region=$GCP_REGION \
    --format='value(status.url)' 2>/dev/null || echo "NOT_FOUND")

if [ "$FRONTEND_URL" = "NOT_FOUND" ]; then
    echo -e "${RED}❌ Frontend service not found${NC}"
else
    echo -e "${GREEN}✅ Frontend URL: $FRONTEND_URL${NC}"
    
    # Test frontend health
    echo -e "${YELLOW}   Testing frontend health...${NC}"
    HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL/health" || echo "000")
    if [ "$HEALTH_RESPONSE" = "200" ]; then
        echo -e "${GREEN}   ✅ Frontend health check: OK${NC}"
    else
        echo -e "${RED}   ❌ Frontend health check failed: HTTP $HEALTH_RESPONSE${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}3. Checking Frontend Environment Variables...${NC}"
FRONTEND_ENV=$(gcloud run services describe chatkit-frontend \
    --region=$GCP_REGION \
    --format='value(spec.template.spec.containers[0].env)' 2>/dev/null || echo "NOT_FOUND")

if [ "$FRONTEND_ENV" = "NOT_FOUND" ]; then
    echo -e "${RED}❌ Could not get frontend environment variables${NC}"
else
    echo "$FRONTEND_ENV" | grep -i "BACKEND_URL" || echo -e "${RED}   ❌ BACKEND_URL not set in frontend${NC}"
fi

echo ""
echo -e "${YELLOW}4. Checking Frontend Logs (last 10 lines)...${NC}"
gcloud run services logs read chatkit-frontend \
    --region=$GCP_REGION \
    --limit=10 \
    2>/dev/null || echo -e "${RED}Could not read frontend logs${NC}"

echo ""
echo -e "${YELLOW}5. Checking Backend Logs (last 10 lines)...${NC}"
gcloud run services logs read chatkit-backend \
    --region=$GCP_REGION \
    --limit=10 \
    2>/dev/null || echo -e "${RED}Could not read backend logs${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Debug Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ "$BACKEND_URL" != "NOT_FOUND" ] && [ "$FRONTEND_URL" != "NOT_FOUND" ]; then
    echo -e "${YELLOW}Quick Test Commands:${NC}"
    echo ""
    echo "# Test backend directly:"
    echo "curl $BACKEND_URL/health"
    echo "curl -X OPTIONS $BACKEND_URL/chatkit -v"
    echo ""
    echo "# Test frontend:"
    echo "curl $FRONTEND_URL/health"
    echo ""
    echo "# Open frontend in browser:"
    echo "open $FRONTEND_URL"
fi
