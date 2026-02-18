[root@ai-infusion-vikash-singh dockerfile-pipelines]# cat build.sh
#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-openwebui-pipelines}"
TAG="${TAG:-latest}"
PLATFORM="${PLATFORM:-linux/ppc64le}"
NO_CACHE="${NO_CACHE:-false}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE} Building ${IMAGE_NAME}:${TAG} (${PLATFORM})${NC}"

podman build \
  ${NO_CACHE:+--no-cache} \
  --platform "${PLATFORM}" \
  --build-arg MINIMUM_BUILD=false \
  --build-arg USE_CUDA=false \
  --build-arg USE_CUDA_VER=cpu \
  --build-arg LIBDATADOG_VERSION=v25.0.0 \
  --build-arg DDTRACE_VERSION=v4.3.0 \
  -t "${IMAGE_NAME}:${TAG}" \
  -t "${IMAGE_NAME}:latest" \
  .

SIZE=$(podman image inspect "${IMAGE_NAME}:${TAG}" --format='{{.Size}}' 2>/dev/null | awk '{printf "%.2fGB", $1/1024/1024/1024}')
echo -e "${GREEN} Complete: ${IMAGE_NAME}:${TAG} (${SIZE})${NC}"