#!/bin/bash
# build-and-push.sh - Build Docker image and push to ECR
set -euo pipefail

# Configuration
REGION="${AWS_REGION:-ap-southeast-2}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPOSITORY_NAME="mssql-bcp-export-bcp"
IMAGE_TAG="${1:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARN:${NC} $1"
}

# ============================================
# Validate prerequisites
# ============================================
log "Validating prerequisites..."

if ! command -v docker &> /dev/null; then
    error "Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    error "AWS CLI is not installed or not in PATH"
    exit 1
fi

# Test AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    error "AWS credentials not configured or invalid"
    exit 1
fi

log "✓ Prerequisites validated"

# ============================================
# Get ECR repository URL
# ============================================
log "Fetching ECR repository information..."

ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPOSITORY_NAME}"

log "ECR Repository: $ECR_URL"

# ============================================
# Login to ECR
# ============================================
log "Logging in to ECR..."

if ! aws ecr get-login-password --region "$REGION" | \
    docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"; then
    error "Failed to login to ECR"
    exit 1
fi

log "✓ Successfully logged in to ECR"

# ============================================
# Build Docker image
# ============================================
log "Building Docker image..."
log "  Image: $ECR_URL:$IMAGE_TAG"

BUILD_START=$(date +%s)

if ! docker build -t "$ECR_URL:$IMAGE_TAG" .; then
    error "Docker build failed"
    exit 1
fi

BUILD_DURATION=$(($(date +%s) - BUILD_START))
log "✓ Docker build completed in ${BUILD_DURATION}s"

# Tag as latest if building a version tag
if [ "$IMAGE_TAG" != "latest" ]; then
    log "Tagging image as latest..."
    docker tag "$ECR_URL:$IMAGE_TAG" "$ECR_URL:latest"
fi

# ============================================
# Push to ECR
# ============================================
log "Pushing image to ECR..."

PUSH_START=$(date +%s)

if ! docker push "$ECR_URL:$IMAGE_TAG"; then
    error "Failed to push image to ECR"
    exit 1
fi

if [ "$IMAGE_TAG" != "latest" ]; then
    if ! docker push "$ECR_URL:latest"; then
        warn "Failed to push 'latest' tag (non-fatal)"
    fi
fi

PUSH_DURATION=$(($(date +%s) - PUSH_START))
log "✓ Image pushed to ECR in ${PUSH_DURATION}s"

# ============================================
# Summary
# ============================================
log "=========================================="
log "Docker Build and Push Complete!"
log "=========================================="
log "Repository: $ECR_URL"
log "Tag: $IMAGE_TAG"
log "Build time: ${BUILD_DURATION}s"
log "Push time: ${PUSH_DURATION}s"
log ""
log "Image URI: $ECR_URL:$IMAGE_TAG"
log ""
log "To test locally:"
log "  docker run --rm -e REGION=test -e DATABASE_NAME=TestDB \\"
log "    -e DB_CREDENTIALS='{\"host\":\"localhost\",\"port\":1433,\"username\":\"sa\",\"password\":\"YourPassword\"}' \\"
log "    -e OUTPUT_BUCKET=your-bucket -e OUTPUT_PREFIX=test/ -e TABLES=dbo.TestTable \\"
log "    $ECR_URL:$IMAGE_TAG"
log ""
log "To deploy with Terraform:"
log "  terraform apply"
log "=========================================="
