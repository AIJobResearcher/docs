#!/usr/bin/env bash

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Vacancies Market - Build Script${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================
# Configuration
# ============================================

REPO_OWNER="AIJobResearcher"
REPO_NAME="docs"
BRANCH="${BRANCH:-main}"
DEPLOY_PATH="deploy/vacancies-market/local"

RAW_BASE="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/${DEPLOY_PATH}"

FILES=(
    "docker-compose.yml"
    "Dockerfile"
    "nginx.conf"
)

# ============================================
# Step 1: Download deployment files
# ============================================

echo -e "${BLUE}📡 Downloading deployment files from docs repo...${NC}"
echo "  Source: $RAW_BASE"
echo ""

for file in "${FILES[@]}"; do
    echo -n "  Downloading $file... "
    if curl -sSL --fail "$RAW_BASE/$file" -o "$file" 2>/dev/null; then
        echo -e "${GREEN}done${NC}"
    else
        echo -e "${RED}failed${NC}"
        echo "  ❌ Failed to download $file"
        echo "  URL: $RAW_BASE/$file"
        exit 1
    fi
done

echo ""

# ============================================
# Step 2: Create required directories
# ============================================

echo -e "${BLUE}📁 Creating required directories...${NC}"

if [ ! -d "storage" ]; then
    mkdir -p storage/framework/{sessions,views,cache}
    mkdir -p storage/logs
    mkdir -p storage/app/public
    echo -e "  ${GREEN}Created storage directory structure${NC}"
else
    echo -e "  ${BLUE}storage already exists${NC}"
fi

if [ ! -d "bootstrap/cache" ]; then
    mkdir -p bootstrap/cache
    echo -e "  ${GREEN}Created bootstrap/cache${NC}"
else
    echo -e "  ${BLUE}bootstrap/cache already exists${NC}"
fi

if [ ! -d "public" ]; then
    mkdir -p public
    echo -e "  ${GREEN}Created public directory${NC}"
else
    echo -e "  ${BLUE}public already exists${NC}"
fi

echo ""

# ============================================
# Step 3: Create .env from .env.example
# ============================================

if [ -f ".env.example" ]; then
    if [ ! -f ".env" ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ Created .env from .env.example${NC}"
    else
        echo -e "${BLUE}ℹ️  .env already exists, keeping existing${NC}"
    fi
else
    echo -e "${RED}❌ .env.example not found in project root${NC}"
    echo -e "${RED}   Please create .env.example file first${NC}"
    exit 1
fi

echo ""

# ============================================
# Step 4: Build Docker image
# ============================================

echo -e "${BLUE}🐳 Building Docker image...${NC}"
docker build -f Dockerfile -t vacancies-market:local .

# Move Dockerfile and nginx.conf to deploy/ directory
echo -e "${BLUE}📦 Moving files to deploy/ directory...${NC}"
mkdir -p deploy
mv Dockerfile deploy/
mv nginx.conf deploy/

echo ""

# ============================================
# Step 5: Show summary
# ============================================

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📁 Project structure:${NC}"
echo "  docker-compose.yml  → ./"
echo "  Dockerfile          → ./deploy/"
echo "  nginx.conf          → ./deploy/"
echo "  .env                → ./"
echo ""
echo -e "${BLUE}Commands:${NC}"
echo "  make up    - Start service (docker-compose up -d)"
echo "  make exec  - Open shell in container"
echo "  make down  - Stop service"
echo ""