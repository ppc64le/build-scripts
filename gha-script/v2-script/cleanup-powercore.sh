#!/usr/bin/env bash
# cleanup-powercore.sh — Remove a PowerCore installation and Currency run files.
#
# Usage:
#   cleanup-powercore.sh
set -euo pipefail

echo "=== PowerCore Cleanup ==="

echo "--- Running powercore-uninstall -y ---"
sudo powercore-uninstall -y || true

echo "--- Uninstalling powercore wheels from root pip ---"
PY_CMD=$(command -v python3.12 || command -v python3 || true)
if [ -n "${PY_CMD}" ]; then
  POWERCORE_PKGS=$(sudo "${PY_CMD}" -m pip list 2>/dev/null \
    | awk 'tolower($1) ~ /powercore/ {print $1}' || true)
  if [ -n "${POWERCORE_PKGS}" ]; then
    echo "  Removing: ${POWERCORE_PKGS}"
    echo "${POWERCORE_PKGS}" | xargs sudo "${PY_CMD}" -m pip uninstall -y 2>/dev/null || true
  else
    echo "  No powercore packages found in root pip"
  fi
else
  echo "  WARN: no python3 found — skipping pip uninstall"
fi

echo "--- Removing COS-downloaded files ---"
if [ -d "./powercore-wheels" ]; then
  echo "  Removing ./powercore-wheels/"
  rm -rf ./powercore-wheels
else
  echo "  ./powercore-wheels not found — already clean"
fi

if [ -f "./powercore-config.env" ]; then
  echo "  Removing ./powercore-config.env"
  rm -f ./powercore-config.env
else
  echo "  ./powercore-config.env not found — already clean"
fi

echo "=== Cleanup complete ==="
