#!/usr/bin/env bash
#
# OpenClaw Docker Update Script
# Rebuild and restart OpenClaw Docker container
#
# Usage:
#   ./update.sh                           # Update from main branch
#   ./update.sh --branch feature-branch   # Update from specific branch
#   ./update.sh --init                    # Rebuild and run onboarding
#   ./update.sh --branch pr-123 --init    # Test PR with onboarding
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default values
BRANCH="main"
RUN_INIT=false
CONTAINER_NAME="openclaw-gateway"
IMAGE_TAG="openclaw-local:latest"

# Load .env.local if it exists
if [ -f .env.local ]; then
    echo -e "${CYAN}Loading configuration from .env.local${NC}"
    set -a
    source .env.local
    set +a
fi

# Use environment variables with defaults
OPENCLAW_VOLUME="${OPENCLAW_VOLUME:-$HOME/.openclaw}"
OPENCLAW_WORKSPACE_VOLUME="${OPENCLAW_WORKSPACE_VOLUME:-${OPENCLAW_VOLUME}/workspace}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        --init)
            RUN_INIT=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --branch <name>   Specify branch to build from (default: main)"
            echo "  --init            Run onboarding after rebuild"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Environment (set in .env.local):"
            echo "  OPENCLAW_VOLUME              OpenClaw config directory (default: ~/.openclaw)"
            echo "  OPENCLAW_WORKSPACE_VOLUME    OpenClaw workspace directory (default: ~/.openclaw/workspace)"
            echo ""
            echo "Examples:"
            echo "  $0                           # Update from main"
            echo "  $0 --branch feature-test     # Test a feature branch"
            echo "  $0 --init                    # Rebuild and run onboarding"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BOLD}${BLUE}🦞 OpenClaw Docker Update Script${NC}"
echo ""
echo -e "${CYAN}Branch:${NC} $BRANCH"
echo -e "${CYAN}Volume:${NC} $OPENCLAW_VOLUME"
echo -e "${CYAN}Workspace:${NC} $OPENCLAW_WORKSPACE_VOLUME"
echo -e "${CYAN}Run Init:${NC} $RUN_INIT"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗${NC} Error: Docker is not installed or not in PATH"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo -e "${RED}✗${NC} Error: Docker daemon is not running"
    echo "Please start Docker and try again"
    exit 1
fi

# Step 1: Stop and remove existing container
echo -e "${YELLOW}→${NC} Stopping and removing existing container..."
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Container removed"
else
    echo -e "${CYAN}ℹ${NC} No existing container found"
fi

# Also stop and remove socat proxy if running
if docker ps -a --format '{{.Names}}' | grep -q "^openclaw-socat$"; then
    docker rm -f openclaw-socat 2>/dev/null || true
fi

# Step 2: Build new image
echo ""
echo -e "${YELLOW}→${NC} Building Docker image from branch: ${BOLD}$BRANCH${NC}"

if ! docker build \
    --build-arg OPENCLAW_VERSION="$BRANCH" \
    -t "$IMAGE_TAG" \
    . ; then
    echo ""
    echo -e "${RED}✗${NC} Error: Docker build failed"
    echo ""
    echo "Possible causes:"
    echo "  - The branch '$BRANCH' does not exist in the OpenClaw repository"
    echo "  - Network connectivity issues preventing git clone"
    echo "  - Build dependencies failed to install"
    echo ""
    echo "To verify the branch exists, visit:"
    echo "  https://github.com/openclaw/openclaw/tree/$BRANCH"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker image built successfully"

# Step 3: Run onboarding if --init flag is set
if [ "$RUN_INIT" = true ]; then
    echo ""
    echo -e "${YELLOW}→${NC} Running onboarding wizard..."
    docker run -it --rm \
        -v "$OPENCLAW_VOLUME:/home/node/.openclaw" \
        -v "$OPENCLAW_WORKSPACE_VOLUME:/home/node/.openclaw/workspace" \
        "$IMAGE_TAG" \
        onboard
    echo -e "${GREEN}✓${NC} Onboarding complete"
fi

# Step 4: Start the container
echo ""
echo -e "${YELLOW}→${NC} Starting OpenClaw gateway..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -v "$OPENCLAW_VOLUME:/home/node/.openclaw" \
    -v "$OPENCLAW_WORKSPACE_VOLUME:/home/node/.openclaw/workspace" \
    -p 18789:18789 \
    -p 18790:18790 \
    -e NODE_ENV=production \
    -e OPENCLAW_SKIP_SERVICE_CHECK=true \
    "$IMAGE_TAG" \
    gateway

echo -e "${GREEN}✓${NC} Gateway started"

# Step 5: Start socat proxy
echo ""
echo -e "${YELLOW}→${NC} Starting socat proxy..."
docker run -d \
    --name openclaw-socat \
    --restart unless-stopped \
    --network "container:$CONTAINER_NAME" \
    alpine/socat \
    TCP-LISTEN:18790,fork,bind=0.0.0.0,reuseaddr TCP:127.0.0.1:18789

echo -e "${GREEN}✓${NC} Socat proxy started"

# Final status
echo ""
echo -e "${GREEN}${BOLD}✓ Update complete!${NC}"
echo ""
echo -e "${CYAN}Gateway is running at:${NC} http://localhost:18789"
echo ""
echo -e "${CYAN}Useful commands:${NC}"
echo -e "  View logs:    ${BOLD}docker logs -f $CONTAINER_NAME${NC}"
echo -e "  Stop gateway: ${BOLD}docker stop $CONTAINER_NAME${NC}"
echo -e "  Restart:      ${BOLD}docker restart $CONTAINER_NAME${NC}"
echo ""
