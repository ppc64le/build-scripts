#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:?scan workspace required}"
REPO_ROOT="${2:?repository root required}"
cd "$ROOT"

WHEEL=$(find wheels -maxdepth 1 -type f -name '*.whl' -print -quit)
if [ -z "$WHEEL" ]; then
  echo "ERROR: no V2 wheel found" >&2
  exit 1
fi
cp -f "$WHEEL" ./
export VALIDATE_BUILD_SCRIPT=true
export CLONED_PACKAGE=source

bash "$REPO_ROOT/gha-script/v2-script/scanner-scripts/scancode_wheel_scan.sh"
export GRYPE_BIN="${GRYPE_BIN:?GRYPE_BIN is required}"
bash "$REPO_ROOT/gha-script/v2-script/scanner-scripts/grype_wheel_scan.sh"

mkdir -p wheel
find . -maxdepth 1 -type f -name '*_output.json' ! -name '*_grype_output.json' -exec mv -f {} wheel/ \;
find . -maxdepth 1 -type f -name '*_grype_output.json' -exec mv -f {} wheel/ \;
cp -f "$WHEEL" wheel/
