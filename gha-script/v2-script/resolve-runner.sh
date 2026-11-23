#!/usr/bin/env bash
# resolve-runner.sh — Choose the runner for the build jobs from the package's
# resource_class in build_info.json and the runner requested at dispatch.
#
# Usage:
#   resolve-runner.sh <package_json> [large_runner_label]
#
# Rules (a requested runner is never lowered; there is no 4xlarge runner):
#   requested runner        resource_class         -> runner
#   default                 absent / light         -> default
#   default                 medium / heavy         -> 2xlarge
#   anything else           any                    -> as requested
#
# Output: runner_label=<label> appended to $GITHUB_OUTPUT (or printed if unset)
set -euo pipefail

PKG_JSON="${1:?package_json argument required}"
REQUESTED="${2:-}"

DEFAULT_RUNNER="ubuntu-24.04-ppc64le-p10"
XL2_RUNNER="ubuntu-24.04-ppc64le-2xlarge-p10"

PKG_NAME=$(echo "$PKG_JSON" | jq -r '.package_name // empty')
PKG_NAME_LOWER=$(echo "$PKG_NAME" | tr '[:upper:]' '[:lower:]')
INITIAL_CHAR=${PKG_NAME_LOWER:0:1}

# Same directory lookup as parse-package-json.sh
PKG_DIR="${INITIAL_CHAR}/${PKG_NAME_LOWER}"
if [ ! -d "$PKG_DIR" ] && [ -d "${INITIAL_CHAR}/${PKG_NAME}" ]; then
  PKG_DIR="${INITIAL_CHAR}/${PKG_NAME}"
fi

# resource_class (or resource-class); absent when file/field is missing or unreadable
RESOURCE_CLASS=""
if [ -f "${PKG_DIR}/build_info.json" ]; then
  RESOURCE_CLASS=$(jq -r '.resource_class // .["resource-class"] // ""' "${PKG_DIR}/build_info.json" 2>/dev/null || true)
  RESOURCE_CLASS=$(echo "$RESOURCE_CLASS" | tr '[:upper:]' '[:lower:]' | xargs)
fi

# Only a default trigger (empty, or the default runner itself) is upgraded
RUNNER="${REQUESTED:-$DEFAULT_RUNNER}"
if [ "$RUNNER" = "$DEFAULT_RUNNER" ]; then
  case "$RESOURCE_CLASS" in
    medium|heavy) RUNNER="$XL2_RUNNER" ;;
  esac
fi

echo "package=${PKG_NAME} dir=${PKG_DIR} resource_class='${RESOURCE_CLASS:-<absent>}' requested='${REQUESTED:-<default>}' -> runner=${RUNNER}"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "runner_label=${RUNNER}" >> "$GITHUB_OUTPUT"
else
  echo "runner_label=${RUNNER}"
fi
