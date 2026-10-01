#!/usr/bin/env bash
# print-build-log.sh — Print the full docker build log for every package in the
# most-recent PowerCore BRequest.  Called as a dedicated GHA step after
# poll-pipeline.sh completes and before verify-wheel.sh runs.
#
# Usage:
#   print-build-log.sh <powercore_runtime>
#
# Exit codes:
#   0 — always (log printing is best-effort; missing logs are reported, not fatal)
# Tested on UBI9
set -euo pipefail

POWERCORE_RUNTIME="${1:?PowerCore runtime path required}"

# Locate the most-recent completed BRequest under requests/
BREQUEST=$(sudo -u powercore find "$POWERCORE_RUNTIME/requests" \
  -mindepth 1 -maxdepth 1 -type d -name "BRequest_*" 2>/dev/null \
  | sort | tail -1)

if [ -z "$BREQUEST" ]; then
  echo "No completed BRequest found under $POWERCORE_RUNTIME/requests — skipping log dump"
  exit 0
fi

echo "BRequest: $BREQUEST"
echo "════════════════════════════════════════════════════════════"
echo "  Full Build Log"
echo "════════════════════════════════════════════════════════════"

found_any=false

# ── Gzipped logs (normal post-bookkeeping format) ─────────────────────────────
while IFS= read -r log_gz; do
  [ -z "$log_gz" ] && continue
  found_any=true
  label=$(echo "$log_gz" | sed "s|${BREQUEST}/||" | sed 's|/docker_package\.log\.gz||')
  echo ""
  echo "── ${label} ──────────────────────────────────────────────────"
  sudo -u powercore zcat "$log_gz" 2>/dev/null || true
done < <(sudo -u powercore find "$BREQUEST" -name "docker_package.log.gz" 2>/dev/null | sort)

# ── Plain logs (present during processing, no .gz sibling) ────────────────────
while IFS= read -r log_plain; do
  [ -z "$log_plain" ] && continue
  # Skip if a .gz version was already printed above
  sudo -u powercore test -f "${log_plain}.gz" 2>/dev/null && continue
  found_any=true
  label=$(echo "$log_plain" | sed "s|${BREQUEST}/||" | sed 's|/docker_package\.log||')
  echo ""
  echo "── ${label} ──────────────────────────────────────────────────"
  sudo -u powercore cat "$log_plain" 2>/dev/null || true
done < <(sudo -u powercore find "$BREQUEST" -name "docker_package.log" 2>/dev/null | sort)

if [ "$found_any" = "false" ]; then
  echo "(no docker_package.log / docker_package.log.gz found under $BREQUEST)"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
