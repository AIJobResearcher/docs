#!/usr/bin/env bash

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Parsing&AIConnector - Build Script${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================
# Configuration
# ============================================

REPO_OWNER="AIJobResearcher"
REPO_NAME="docs"
BRANCH="${BRANCH:-main}"
DEPLOY_PATH="deploy/parsing-ai-connector/local"

RAW_BASE="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/${DEPLOY_PATH}"

FILES=(
    "docker-compose.yml"
    "Dockerfile"
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
echo -e "  ${GREEN}Moved Dockerfile → deploy/${NC}"
echo -e "  ${BLUE}docker-compose.yml → ./${NC}"
echo ""

# ============================================
# Step 3: Project files
# ============================================

echo -e "${BLUE}📚 Step 3: Project files...${NC}"
echo -e "  ${BLUE}docs/ and .ai-agent/ are synced by the service-side deploy/sync.sh${NC}"
echo ""

# ============================================
# Step 4: Create .env from .env.example
# ============================================

echo -e "${BLUE}⚙️  Step 4: Configuring environment...${NC}"

if [ -f ".env" ]; then
    echo -e "  ${BLUE}.env already exists — kept as is${NC}"
elif [ -f ".env.example" ]; then
    cp .env.example .env
    echo -e "  ${GREEN}Created .env from .env.example${NC}"
else
    echo -e "${RED}❌ .env.example not found in the project root${NC}"
    echo -e "${RED}   Please create .env.example file first${NC}"
    exit 1
fi

echo ""

# ============================================
# Step 5: Build Docker image
# ============================================

echo -e "${BLUE}🐳 Step 5: Building Docker image...${NC}"
docker build -f deploy/Dockerfile -t parsing-ai-connector:local .

echo ""

# ============================================
# Step 6: Start containers
# ============================================

echo -e "${BLUE}🚀 Step 6: Starting containers...${NC}"
docker compose up -d

echo ""

# ============================================
# Step 7: Wait for infrastructure healthchecks
# ============================================

wait_for_healthy() {
    local name="$1"
    local container="$2"
    local timeout="${3:-90}"
    local elapsed=0
    local status

    echo -n "  $name... "
    while [ "$elapsed" -lt "$timeout" ]; do
        status=$(docker inspect \
            --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
            "$container" 2>/dev/null || echo "missing")

        if [ "$status" = "healthy" ] || [ "$status" = "running" ]; then
            echo -e "${GREEN}${status}${NC}"
            return 0
        fi

        sleep 2
        elapsed=$((elapsed + 2))
    done

    echo -e "${RED}timed out after ${timeout}s (status: ${status})${NC}"
    return 1
}

echo -e "${BLUE}⏳ Step 7: Waiting for services to be ready...${NC}"
wait_for_healthy "postgres" "parsing-ai-postgres"
wait_for_healthy "rabbitmq" "parsing-ai-rabbitmq"
wait_for_healthy "redis" "parsing-ai-redis"

echo ""

# ============================================
# Step 8: Apply database migrations
# ============================================

echo -e "${BLUE}🔧 Step 8: Applying database migrations...${NC}"
docker compose exec -T app alembic upgrade head

echo ""

# ============================================
# Step 9: Show summary
# ============================================

APP_PORT_VALUE="$(sed -n 's/^APP_PORT=//p' .env | tail -n 1)"

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📡 API:${NC} http://localhost:${APP_PORT_VALUE:-8000}"
echo ""
echo -e "${BLUE}Commands:${NC}"
echo "  make up    - Start services"
echo "  make exec  - Open shell in the app container"
echo "  make down  - Stop services"
echo "  make logs  - View logs"
echo ""
