#!/usr/bin/env bash
# verify-wheel.sh — Confirm that PACKAGE_NAME built successfully in PowerCore.
#
# Reads results_summary.csv from the most-recent BRequest_* directory under
# POWERCORE_RUNTIME and checks that the target package has status "success".
# Dependency-package failures are ignored.
#
# Usage:
#   verify-wheel.sh <powercore_runtime> <package_name>
#
# Exit codes:
#   0  — package status is "success"
#   1  — BRequest dir / CSV not found, or package status is not "success"
set -euo pipefail

POWERCORE_RUNTIME="${1:?PowerCore runtime path required}"
PACKAGE_NAME="${2:?package name required}"

# Locate the most-recent BRequest directory
REQUEST_DIR=$(sudo -u powercore find "$POWERCORE_RUNTIME" -type d -name 'BRequest_*' 2>/dev/null | sort | tail -1)
if [ -z "$REQUEST_DIR" ]; then
  echo "ERROR: No BRequest directory found under $POWERCORE_RUNTIME." >&2
  exit 1
fi

# Locate results_summary.csv
CSV=$(sudo -u powercore find "$REQUEST_DIR" -name 'results_summary.csv' 2>/dev/null | head -1)
if [ -z "$CSV" ]; then
  echo "ERROR: results_summary.csv not found — PowerCore post-process may have failed." >&2
  exit 1
fi
echo "Results CSV: $CSV"

# Normalize: hyphens and underscores are interchangeable in package names
PKG_NORM="${PACKAGE_NAME//-/_}"
STATUS=$(sudo -u powercore awk -F',' -v pkg="$PKG_NORM" '
  NR==1 {
    for (i=1;i<=NF;i++) {
      gsub(/\r/,"",$i); gsub(/^ +| +$/,"",$i)
      if ($i=="Package" || $i=="package_name" || $i=="name") ni=i
      if ($i=="Validation Status" || $i=="status") si=i
    }
    next
  }
  NF>1 {
    gsub(/\r/,"")
    n=(ni?$ni:"?"); gsub(/-/,"_",n); gsub(/^ +| +$/,"",n)
    s=(si?$si:"");  gsub(/^ +| +$/,"",s)
    if (n==pkg && si) { print s; exit }
  }
' "$CSV" 2>/dev/null || true)

echo "Build status for '${PACKAGE_NAME}': ${STATUS:-not found}"
if [ "$STATUS" = "success" ]; then
  echo "Wheel build verified for '${PACKAGE_NAME}'."
else
  echo "ERROR: '${PACKAGE_NAME}' did not build successfully (status=${STATUS:-not found})." >&2
  echo "All package results:"
  sudo -u powercore awk -F',' 'NR>1 && NF>1 { gsub(/\r/,""); print "  " $0 }' "$CSV" || true
  exit 1
fi
