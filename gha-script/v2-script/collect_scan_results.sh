#!/usr/bin/env bash
# collect_scan_results.sh — Download per-UBI-version × per-Python-version scan
# result tarballs from the powercore-builds COS bucket and extract them into a
# single merged v2-scan-workspace, with clear log output for each combination.
#
# Usage:
#   collect_scan_results.sh <package_name> <package_version> <workspace_dir> <run_id>
#
# Required env vars:
#   GHA_CURRENCY_SERVICE_ID_API_KEY  — IBM Cloud IAM API key
#
# For each UBI × Python version combination it tries to download:
#   powercore-builds/<package_name>/<package_version>/<run_id>/<package_name>-<package_version>-v2-scan-result-<ubi_ver>-<py_ver>.tar.gz
# and extracts it into <workspace_dir>.
#
# The <run_id> argument (GitHub Actions run ID) ensures only tarballs uploaded
# by this specific workflow run are collected, preventing cross-run contamination
# when the same package/version has been built in multiple runs.
#
# A 404 is silently skipped (the corresponding wheel job was skipped or not
# requested).  Any other HTTP error is fatal.
#
# Exits 1 if none of the tarballs were found (nothing to process).
set -euo pipefail

PACKAGE_NAME="${1:?package_name required}"
PACKAGE_VERSION="${2:?package_version required}"
WORKSPACE_DIR="${3:-v2-scan-workspace}"
RUN_ID="${4:?run_id required}"

: "${GHA_CURRENCY_SERVICE_ID_API_KEY:?GHA_CURRENCY_SERVICE_ID_API_KEY is required}"

mkdir -p "${WORKSPACE_DIR}/wheel"

echo "============================================================"
echo "  V2 Scan Results — Downloading & Collecting Artifacts"
echo "  Package  : ${PACKAGE_NAME}"
echo "  Version  : ${PACKAGE_VERSION}"
echo "  Workspace: ${WORKSPACE_DIR}"
echo "  Bucket   : powercore-builds"
echo "============================================================"

# Obtain IAM token once and reuse across all downloads
echo "--- Fetching IAM token ---"
token_request=$(curl -sS -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=${GHA_CURRENCY_SERVICE_ID_API_KEY}")

if [[ $(echo "${token_request}" | jq -r '.errorCode // empty') != "" ]]; then
  echo "ERROR: IAM token request failed."
  exit 1
fi
TOKEN=$(echo "${token_request}" | jq -r '.access_token // empty')
if [[ -z "${TOKEN}" ]]; then
  echo "ERROR: IAM access token could not be retrieved."
  exit 1
fi
echo "OK: IAM token obtained"

BUCKET_URL="https://s3.us.cloud-object-storage.appdomain.cloud/powercore-builds"
found_any=false

for UBI_VER in ubi9 ubi10; do
  if [[ "${UBI_VER}" == "ubi9" ]]; then
    PY_VERS="3.10 3.11 3.12 3.13 3.14"
  else
    PY_VERS="3.12 3.13 3.14"
  fi
  for PY_VER in ${PY_VERS}; do
    TARBALL="${PACKAGE_NAME}-${PACKAGE_VERSION}-v2-scan-result-${UBI_VER}-${PY_VER}.tar.gz"
    OBJECT_KEY="${PACKAGE_NAME}/${PACKAGE_VERSION}/${RUN_ID}/${TARBALL}"

    echo ""
    echo "------------------------------------------------------------"
    echo "  ${UBI_VER} / Python ${PY_VER}"
    echo "  Object : ${OBJECT_KEY}"
    echo "------------------------------------------------------------"

    http_code=$(curl -sS -w "%{http_code}" -o "${TARBALL}" \
      -H "Authorization: bearer ${TOKEN}" \
      "${BUCKET_URL}/${OBJECT_KEY}")

    if [[ "${http_code}" == "200" ]]; then
      echo "  Downloaded OK."
      tar -xzf "${TARBALL}" --strip-components=1 -C "${WORKSPACE_DIR}"
      rm -f "${TARBALL}"
      found_any=true
      echo "  Extracted successfully."

      echo ""
      echo "  Wheel scan files:"
      PY_TAG="cp${PY_VER/./}"
      wheel_files=$(find "${WORKSPACE_DIR}/wheel" -maxdepth 1 -name "*${PY_TAG}*" 2>/dev/null | sort)
      if [ -n "${wheel_files}" ]; then
        while IFS= read -r f; do
          SIZE=$(du -sh "$f" | cut -f1)
          printf "    %-8s  %s\n" "${SIZE}" "$(basename "$f")"
        done <<< "${wheel_files}"
      else
        echo "    (none)"
      fi

      echo ""
      echo "  Source scan files:"
      source_files=$(find "${WORKSPACE_DIR}/source" -maxdepth 1 -type f 2>/dev/null | sort)
      if [ -n "${source_files}" ]; then
        while IFS= read -r f; do
          SIZE=$(du -sh "$f" | cut -f1)
          printf "    %-8s  %s\n" "${SIZE}" "$(basename "$f")"
        done <<< "${source_files}"
      else
        echo "    (none)"
      fi

    elif [[ "${http_code}" == "404" ]]; then
      rm -f "${TARBALL}"
      echo "  SKIPPED — not found in COS (job may have been skipped or not requested)."
    else
      rm -f "${TARBALL}"
      echo "  ERROR: COS GET failed (HTTP ${http_code})."
      exit 1
    fi
  done
done

echo ""
echo "============================================================"
echo "  All ScanCode JSON files collected:"
echo "============================================================"
scancode_files=$(find "${WORKSPACE_DIR}/wheel" -maxdepth 1 \
  -name '*_output.json' ! -name '*_grype_output.json' 2>/dev/null | sort)
if [ -n "${scancode_files}" ]; then
  while IFS= read -r f; do
    SIZE=$(du -sh "$f" | cut -f1)
    printf "  %-8s  %s\n" "${SIZE}" "$(basename "$f")"
  done <<< "${scancode_files}"
else
  echo "  (none)"
fi
echo "============================================================"

if [ "${found_any}" = "false" ]; then
  echo ""
  echo "ERROR: No scan result tarballs were found in COS. Cannot proceed." >&2
  exit 1
fi
