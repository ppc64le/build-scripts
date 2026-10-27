#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:?scan workspace required}"
REPO_ROOT="${2:?repository root required}"
cd "$ROOT"
source package-cache/variable.sh
source package-cache/scanner-env.sh

if [ ! -d package-cache/source ]; then
  echo "ERROR: V2 source directory was not found" >&2
  exit 1
fi

rm -rf source
mkdir -p source

bash "$REPO_ROOT/gha-script/v2-script/scanner-scripts/trivy_code_scan.sh"
mv package-cache/trivy_source_vulnerabilities_results.json package-cache/trivy_source_sbom_results.cyclonedx source/

bash "$REPO_ROOT/gha-script/v2-script/scanner-scripts/syft_code_scan.sh"
mv package-cache/syft_source_sbom_results.json source/

export GRYPE_BIN="${GRYPE_BIN:?GRYPE_BIN is required}"
bash "$REPO_ROOT/gha-script/v2-script/scanner-scripts/grype_code_scan.sh"
mv package-cache/grype_source_sbom_results.json package-cache/grype_source_vulnerabilities_results.json source/
