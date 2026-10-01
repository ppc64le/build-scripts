#!/usr/bin/env bash
# download_from_cos.sh — Download a file from the powercore-builds COS bucket.
#
# Usage:
#   download_from_cos.sh <filename>
#
# Required env vars:
#   GHA_CURRENCY_SERVICE_ID_API_KEY  — IBM Cloud IAM API key
#   PACKAGE_NAME                     — package name (path prefix in bucket)
#   PACKAGE_VERSION                  — package version (path prefix in bucket)
#   GHA_RUN_ID                       — (optional) GitHub Actions run ID; when set,
#                                      scopes the path to match upload_to_cos.sh:
#                                      <package>/<version>/<run_id>/<file>
#
# Downloads: <PACKAGE_NAME>/<PACKAGE_VERSION>/[<GHA_RUN_ID>/]<filename>  →  ./<filename>
# Exits 0 on success, 1 on failure.
# Pass --optional as second argument to exit 0 (with a warning) when the
# object does not exist — useful for skipped parallel jobs.
set -euo pipefail

FILE="${1:?filename argument required}"
OPTIONAL="${2:-}"

: "${GHA_CURRENCY_SERVICE_ID_API_KEY:?GHA_CURRENCY_SERVICE_ID_API_KEY is required}"
: "${PACKAGE_NAME:?PACKAGE_NAME is required}"
: "${PACKAGE_VERSION:?PACKAGE_VERSION is required}"

BUCKET="powercore-builds"
BUCKET_URL="https://s3.us.cloud-object-storage.appdomain.cloud/${BUCKET}"
if [[ -n "${GHA_RUN_ID:-}" ]]; then
  OBJECT_KEY="${PACKAGE_NAME}/${PACKAGE_VERSION}/${GHA_RUN_ID}/${FILE}"
else
  OBJECT_KEY="${PACKAGE_NAME}/${PACKAGE_VERSION}/${FILE}"
fi

echo "--- Downloading from COS ---"
echo "  Bucket     : ${BUCKET}"
echo "  Object key : ${OBJECT_KEY}"

echo "--- Fetching IAM token ---"
token_request=$(curl -sS -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=${GHA_CURRENCY_SERVICE_ID_API_KEY}")

if [[ $(echo "${token_request}" | jq -r '.errorCode') != "null" ]]; then
  echo "ERROR: IAM token request failed. Response: ${token_request}"
  exit 1
fi

token=$(echo "${token_request}" | jq -r '.access_token')
if [[ -z "${token}" || "${token}" == "null" ]]; then
  echo "ERROR: IAM token missing from response."
  exit 1
fi
echo "OK: IAM token obtained"

http_code=$(curl -sS -w "%{http_code}" -o "${FILE}" \
  -H "Authorization: bearer ${token}" \
  "${BUCKET_URL}/${OBJECT_KEY}")

if [[ "${http_code}" == "200" ]]; then
  SIZE=$(du -sh "${FILE}" | cut -f1)
  echo "Downloaded: ${FILE} (${SIZE})"
elif [[ "${http_code}" == "404" && "${OPTIONAL}" == "--optional" ]]; then
  rm -f "${FILE}"
  echo "WARNING: ${OBJECT_KEY} not found in COS (skipped — job may have been skipped or failed)."
  exit 0
else
  rm -f "${FILE}"
  echo "ERROR: COS GET failed (HTTP ${http_code}) for ${OBJECT_KEY}"
  exit 1
fi
