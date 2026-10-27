#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:?scan workspace required}"
REPO_ROOT="${2:?repository root required}"
cd "$ROOT"

if [ ! -f image/image.tar ]; then
  echo "No image.tar found; skipping V2 image scan."
  exit 0
fi

rm -rf image/results
mkdir -p image/results
docker load -i image/image.tar
IMAGE_NAME=$(docker images --format '{{.Repository}}:{{.Tag}}' | head -1)
if [ -z "$IMAGE_NAME" ]; then
  echo "ERROR: unable to determine loaded image name" >&2
  exit 1
fi
export IMAGE_NAME BUILD_DOCKER=true

bash "$REPO_ROOT/gha-script/v2-script/scanner-scripts/trivy_image_scan.sh"
mv trivy_image_vulnerabilities_results.json trivy_image_sbom_results.cyclonedx image/results/

bash "$REPO_ROOT/gha-script/v2-script/scanner-scripts/syft_image_scan.sh"
mv syft_image_sbom_results.json image/results/

export GRYPE_BIN="${GRYPE_BIN:?GRYPE_BIN is required}"
bash "$REPO_ROOT/gha-script/v2-script/scanner-scripts/grype_image_scan.sh"
mv grype_image_sbom_results.json grype_image_vulnerabilities_results.json image/results/
