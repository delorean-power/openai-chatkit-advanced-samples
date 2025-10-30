#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Cleaning up local Docker test containers...${NC}"

# Stop containers
docker stop chatkit-backend-test chatkit-frontend-test 2>/dev/null || true

# Remove containers
docker rm chatkit-backend-test chatkit-frontend-test 2>/dev/null || true

# Remove images
docker rmi chatkit-backend-test chatkit-frontend-test 2>/dev/null || true

echo -e "${GREEN}✓ Cleanup complete${NC}"
