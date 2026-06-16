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

echo -e "${BLUE}📡 Step 1: Downloading deployment files from docs repo...${NC}"
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
# Step 2: Move files to deploy/ directory
# ============================================

echo -e "${BLUE}📦 Step 2: Moving files to deploy/ directory...${NC}"
mkdir -p deploy

mv Dockerfile deploy/
mv nginx.conf deploy/
echo -e "  ${GREEN}Moved Dockerfile → deploy/${NC}"
echo -e "  ${GREEN}Moved nginx.conf → deploy/${NC}"
echo -e "  ${BLUE}docker-compose.yml → ./${NC}"
echo ""

# ============================================
# Step 3: Create required directories
# ============================================

echo -e "${BLUE}📁 Step 3: Creating required directories...${NC}"

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
# Step 4: Create .env from .env.example
# ============================================

echo -e "${BLUE}⚙️  Step 4: Configuring environment...${NC}"

if [ -f ".env.example" ]; then
    cp .env.example .env
    echo -e "  ${GREEN}Created fresh .env from .env.example${NC}"
else
    echo -e "${RED}❌ .env.example not found in project root${NC}"
    echo -e "${RED}   Please create .env.example file first${NC}"
    exit 1
fi

echo ""

# ============================================
# Step 5: Build Docker image
# ============================================

echo -e "${BLUE}🐳 Step 5: Building Docker image...${NC}"
docker build -f deploy/Dockerfile -t vacancies-market:local .

echo ""

# ============================================
# Step 6: Start containers
# ============================================

echo -e "${BLUE}🚀 Step 6: Starting containers...${NC}"
docker-compose up -d

echo ""

# ============================================
# Step 7: Wait for services to be ready
# ============================================

echo -e "${BLUE}⏳ Step 7: Waiting for services to be ready...${NC}"
sleep 5
echo -e "  ${GREEN}Services started${NC}"

echo ""

# ============================================
# Step 8: Setup application inside container
# ============================================

echo -e "${BLUE}🔧 Step 8: Setting up application...${NC}"

echo -n "  Configuring Git... "
docker-compose exec -T app sh -c "git config --global --add safe.directory /var/www" 2>/dev/null && echo -e "${GREEN}done${NC}" || echo -e "${YELLOW}skipped${NC}"

echo -n "  Installing composer dependencies... "
docker-compose exec -T app sh -c "composer install --no-interaction --optimize-autoloader" 2>/dev/null && echo -e "${GREEN}done${NC}" || echo -e "${RED}failed${NC}"

echo -n "  Generating APP_KEY... "
docker-compose exec -T app php artisan key:generate --force 2>/dev/null && echo -e "${GREEN}done${NC}" || echo -e "${YELLOW}skipped${NC}"

echo -n "  Running migrations... "
docker-compose exec -T app php artisan migrate --force 2>/dev/null && echo -e "${GREEN}done${NC}" || echo -e "${YELLOW}skipped (no migrations)${NC}"

echo -n "  Running seeders... "
docker-compose exec -T app php artisan db:seed --force 2>/dev/null && echo -e "${GREEN}done${NC}" || echo -e "${YELLOW}skipped (no seeders)${NC}"

echo -n "  Clearing cache... "
docker-compose exec -T app php artisan optimize:clear 2>/dev/null && echo -e "${GREEN}done${NC}" || echo -e "${YELLOW}skipped${NC}"

echo ""

# ============================================
# Step 9: Show summary
# ============================================

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📡 API:${NC} http://localhost:8001"
echo ""
echo -e "${BLUE}Commands:${NC}"
echo "  make up    - Start service"
echo "  make exec  - Open shell in container"
echo "  make down  - Stop service"
echo "  make logs  - View logs"
echo ""