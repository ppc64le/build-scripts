#!/usr/bin/env bash
# parse-package-json.sh — Validate package_json input, extract fields, write variable.sh
#
# Usage:
#   parse-package-json.sh <package_json> \
#     <v2_enabled> <trigger_all_python_builds> <build_docker>
#
# Output: variable.sh written to CWD
set -euo pipefail

PKG_JSON="${1:?package_json argument required}"
V2_ENABLED="${2:-true}"
TRIGGER_ALL_PYTHON_BUILDS="${3:-false}"
BUILD_DOCKER="${4:-false}"

echo "--- Validating package_json ---"
if ! echo "$PKG_JSON" | jq empty 2>/dev/null; then
  echo "ERROR: package_json is not valid JSON"
  exit 1
fi

# Extract fields — technology_version key may have a leading space in some
# callers (e.g. {" technology_version":"3.12"}), handle both forms.
PKG_NAME=$(echo "$PKG_JSON" | jq -r '.package_name    // empty')
PKG_VER=$(echo  "$PKG_JSON" | jq -r '.package_version // empty')
TECH=$(echo     "$PKG_JSON" | jq -r '.technology      // empty')
TECH_VER=$(echo "$PKG_JSON" | jq -r '.technology_version // (.["  technology_version"] // "")' 2>/dev/null || echo "")
UBI_VER=$(echo  "$PKG_JSON" | jq -r '.ubi_version // ""')
ARCH=$(echo "$PKG_JSON" | jq -r '.arch // "ppc64le"')

echo "--- Validating required fields ---"
for field in PKG_NAME PKG_VER TECH; do
  eval "val=\$$field"
  if [ -z "$val" ]; then
    echo "ERROR: Required field missing in package_json: $field"
    exit 1
  fi
done

# Default ubi_version to ubi9 when blank
UBI_VER="${UBI_VER:-ubi9}"

echo "--- Writing variable.sh ---"
printf '%s\n' \
  "PACKAGE_NAME=\"${PKG_NAME}\"" \
  "PACKAGE_VERSION=\"${PKG_VER}\"" \
  "TECHNOLOGY=\"${TECH}\"" \
  "TECHNOLOGY_VERSION=\"${TECH_VER}\"" \
  "UBI_VERSION=\"${UBI_VER}\"" \
  "ARCH=\"${ARCH}\"" \
  "V2_ENABLED=\"${V2_ENABLED}\"" \
  "TRIGGER_ALL_PYTHON_BUILDS=\"${TRIGGER_ALL_PYTHON_BUILDS}\"" \
  "BUILD_DOCKER=\"${BUILD_DOCKER}\"" \
  > variable.sh

echo "===== variable.sh ====="
cat variable.sh
echo "======================="
echo "OK: ${PKG_NAME} ${PKG_VER} (${TECH} ${TECH_VER:-default}) arch=${ARCH} ubi=${UBI_VER}"
