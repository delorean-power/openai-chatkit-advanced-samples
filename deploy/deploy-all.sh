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

# Load configuration for domain info
if [ -f .env.deploy ]; then
    source .env.deploy
fi

echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Set up internal domain mapping:"
echo "   ./deploy/setup-domain.sh"
echo ""
echo "2. Configure DNS for lightshift.local domain"
echo ""
echo "3. Add domain to ChatKit allowlist"
echo ""
echo "4. Update CHATKIT_DOMAIN_KEY in .env.deploy and redeploy frontend"
echo ""

if [ ! -z "$FRONTEND_CUSTOM_DOMAIN" ]; then
    echo -e "${YELLOW}Your services will be available at:${NC}"
    echo "  Frontend: https://${FRONTEND_CUSTOM_DOMAIN}"
    echo "  Backend:  https://${BACKEND_CUSTOM_DOMAIN:-chatkit-api.lightshift.local}"
    echo ""
fi
