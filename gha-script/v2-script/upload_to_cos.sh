#!/usr/bin/env bash
# upload_to_cos.sh — Upload a file to the powercore-builds COS bucket under
# <PACKAGE_NAME>/<PACKAGE_VERSION>/<GHA_RUN_ID>/<filename>.
#
# Usage:
#   upload_to_cos.sh <file>
#
# Required env vars:
#   GHA_CURRENCY_SERVICE_ID_API_KEY  — IBM Cloud IAM API key
#   PACKAGE_NAME                     — package name (path prefix in bucket)
#   PACKAGE_VERSION                  — package version (path prefix in bucket)
#   GHA_RUN_ID                       — GitHub Actions run ID (isolates this run's
#                                      uploads from other runs of the same package/version)
#
# The object key in COS will be:
#   <PACKAGE_NAME>/<PACKAGE_VERSION>/<GHA_RUN_ID>/<basename of file>
set -euo pipefail

FILE="${1:?file argument required}"

: "${GHA_CURRENCY_SERVICE_ID_API_KEY:?GHA_CURRENCY_SERVICE_ID_API_KEY is required}"
: "${PACKAGE_NAME:?PACKAGE_NAME is required}"
: "${PACKAGE_VERSION:?PACKAGE_VERSION is required}"
: "${GHA_RUN_ID:?GHA_RUN_ID is required}"

BUCKET="powercore-builds"
BUCKET_URL="https://s3.us.cloud-object-storage.appdomain.cloud/${BUCKET}"
OBJECT_KEY="${PACKAGE_NAME}/${PACKAGE_VERSION}/${GHA_RUN_ID}/$(basename "${FILE}")"

echo "--- Uploading to COS ---"
echo "  File       : ${FILE}"
echo "  Bucket     : ${BUCKET}"
echo "  Object key : ${OBJECT_KEY}"

echo "--- Fetching IAM token ---"
token_request=$(curl -sS -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=${GHA_CURRENCY_SERVICE_ID_API_KEY}")

if [[ $(echo "${token_request}" | jq -r '.errorCode // empty') != "" ]]; then
  echo "ERROR: IAM token request failed."
  exit 1
fi

token=$(echo "${token_request}" | jq -r '.access_token // empty')
if [[ -z "${token}" ]]; then
  echo "ERROR: IAM access token could not be retrieved."
  exit 1
fi
echo "OK: IAM token obtained"

echo "--- Uploading ${FILE} ---"
response=$(curl -sS -X PUT \
  -H "Authorization: bearer ${token}" \
  -H "Content-Type: application/gzip" \
  -T "${FILE}" \
  "${BUCKET_URL}/${OBJECT_KEY}")

if echo "${response}" | grep -q "<Error>"; then
  echo "ERROR: COS PUT failed. Response: ${response}"
  exit 1
fi

echo "Successfully uploaded: ${BUCKET_URL}/${OBJECT_KEY}"
