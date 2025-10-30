#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Local Docker Test${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Load configuration
if [ -f .env.deploy ]; then
    source .env.deploy
else
    echo -e "${RED}Error: .env.deploy file not found${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Build and test backend
echo -e "${YELLOW}Building backend image...${NC}"
cd backend
docker build -t chatkit-backend-test .

echo -e "${YELLOW}Starting backend container...${NC}"
docker run -d \
    --name chatkit-backend-test \
    -p 8080:8080 \
    -e OPENAI_API_KEY="$OPENAI_API_KEY" \
    -e PORT=8080 \
    chatkit-backend-test

echo -e "${YELLOW}Waiting for backend to start...${NC}"
sleep 5

# Test backend health
echo -e "${YELLOW}Testing backend health...${NC}"
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backend is healthy${NC}"
    echo "Response: $HEALTH_RESPONSE"
else
    echo -e "${RED}✗ Backend health check failed${NC}"
    docker logs chatkit-backend-test
    docker stop chatkit-backend-test
    docker rm chatkit-backend-test
    exit 1
fi

# Get backend container IP for frontend
BACKEND_URL="http://localhost:8080"

cd ..

# Build and test frontend
echo ""
echo -e "${YELLOW}Building frontend image...${NC}"
cd frontend
docker build \
    --build-arg VITE_CHATKIT_API_URL="$BACKEND_URL" \
    -t chatkit-frontend-test .

echo -e "${YELLOW}Starting frontend container...${NC}"
docker run -d \
    --name chatkit-frontend-test \
    -p 8081:8080 \
    -e BACKEND_URL="$BACKEND_URL" \
    chatkit-frontend-test

echo -e "${YELLOW}Waiting for frontend to start...${NC}"
sleep 3

# Test frontend health
echo -e "${YELLOW}Testing frontend health...${NC}"
FRONTEND_HEALTH=$(curl -s http://localhost:8081/health)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Frontend is healthy${NC}"
    echo "Response: $FRONTEND_HEALTH"
else
    echo -e "${RED}✗ Frontend health check failed${NC}"
    docker logs chatkit-frontend-test
fi

cd ..

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Local test containers running!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Access the application:${NC}"
echo "  Frontend: http://localhost:8081"
echo "  Backend:  http://localhost:8080"
echo ""
echo -e "${YELLOW}View logs:${NC}"
echo "  Backend:  docker logs -f chatkit-backend-test"
echo "  Frontend: docker logs -f chatkit-frontend-test"
echo ""
echo -e "${YELLOW}Stop and cleanup:${NC}"
echo "  docker stop chatkit-backend-test chatkit-frontend-test"
echo "  docker rm chatkit-backend-test chatkit-frontend-test"
echo "  docker rmi chatkit-backend-test chatkit-frontend-test"
echo ""
echo -e "${YELLOW}Or run the cleanup script:${NC}"
echo "  ./deploy/local-cleanup.sh"
echo ""
