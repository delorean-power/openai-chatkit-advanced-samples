#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Full ChatKit Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Run setup
echo -e "${YELLOW}Step 1: Running setup...${NC}"
./deploy/setup.sh

echo ""
echo -e "${YELLOW}Step 2: Deploying backend...${NC}"
./deploy/deploy-backend.sh

echo ""
echo -e "${YELLOW}Step 3: Deploying frontend...${NC}"
./deploy/deploy-frontend.sh

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
