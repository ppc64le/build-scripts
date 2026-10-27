#!/usr/bin/env bash
# extract_wheel_licenses.sh — Extract SPDX license identifiers from ScanCode
# JSON outputs produced by the wheel scan, and write a per-wheel _licenses.json.
#
# Usage:
#   extract_wheel_licenses.sh <scan_workspace> <repo_root>
set -euo pipefail

ROOT="${1:?scan workspace required}"
REPO_ROOT="${2:?repository root required}"
cd "$ROOT"
mkdir -p wheel

echo "============================================================"
echo "  V2 Wheel License Extraction"
echo "  Workspace : ${ROOT}"
echo "============================================================"

shopt -s nullglob
files=(wheel/*_output.json)

if [ "${#files[@]}" -eq 0 ]; then
  echo "  No ScanCode wheel JSON files found; skipping license extraction."
  echo "============================================================"
  exit 0
fi

echo "  ScanCode JSON files found: ${#files[@]}"
echo ""

for json_file in "${files[@]}"; do
  if [[ "$json_file" == *_grype_output.json ]]; then
    continue
  fi

  echo "--- $(basename "$json_file") ---"

  licenses=$(python3 "$REPO_ROOT/gha-script/v2-script/licenses_extract_script.py" "$json_file")

  if [ -n "$licenses" ]; then
    echo "$licenses"
  else
    echo "(no licenses detected)"
  fi

  # Write _licenses.json alongside the source JSON
  python3 - "$json_file" "$licenses" <<'PY'
import json
import sys
from pathlib import Path

source = Path(sys.argv[1])
out = source.with_name(source.stem + "_licenses.json")
out.write_text(json.dumps({"source": source.name, "licenses": sys.argv[2].split(", ") if sys.argv[2] else []}, indent=2) + "\n")
PY

  echo ""
done

echo "============================================================"
echo "  License extraction complete."
echo "  Output files:"
for f in wheel/*_licenses.json; do
  SIZE=$(du -sh "$f" | cut -f1)
  printf "    %-8s  %s\n" "${SIZE}" "$(basename "$f")"
done
echo "============================================================"
