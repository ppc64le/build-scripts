#!/usr/bin/env bash
# load_variable.sh — Load variable.sh exports into the GitHub Actions job environment.
#
# Reads variable.sh line by line, skipping blank lines and comments, and writes
# KEY=VALUE pairs to $GITHUB_ENV.  UBI_VERSION and PYTHON_VERSION are always
# skipped because those are set at job level and must not be overwritten.
#
# Usage:
#   load_variable.sh
set -euo pipefail

echo "===== variable.sh ====="
cat variable.sh
echo "======================="

while IFS='=' read -r key value; do
  key="${key// /}"
  [[ -z "$key" || "$key" == \#* ]] && continue
  # UBI_VERSION and PYTHON_VERSION are set at job level — do not overwrite
  [[ "$key" == "UBI_VERSION" || "$key" == "PYTHON_VERSION" ]] && continue
  value="${value%\"}"
  value="${value#\"}"
  echo "${key}=${value}" >> "$GITHUB_ENV"
done < variable.sh
