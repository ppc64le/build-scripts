#!/usr/bin/env bash
# download-wheels.sh — Fetch PowerCore wheels from COS.
#
# Usage:
#   download-wheels.sh <api_key> <powercore_version>
#
# Output: powercore-wheels/ directory in CWD
set -euo pipefail

API_KEY="${1:?api_key argument required}"
POWERCORE_VERSION="${2:?powercore_version argument required}"

BUCKET_URL="https://s3.us.cloud-object-storage.appdomain.cloud/powercore-wheels-staging"
LIST_URL="${BUCKET_URL}?list-type=2"

echo "--- Download config ---"
echo "  BUCKET_URL        : ${BUCKET_URL}"
echo "  POWERCORE_VERSION : ${POWERCORE_VERSION}"

MAX_ATTEMPTS=3
RETRY_DELAY=10

for attempt in $(seq 1 $MAX_ATTEMPTS); do
  echo "--- Attempt ${attempt}/${MAX_ATTEMPTS} ---"

  echo "--- Fetching IAM token ---"
  token_request=$(curl -sS -X POST https://iam.cloud.ibm.com/identity/token \
    -H "content-type: application/x-www-form-urlencoded" \
    -H "accept: application/json" \
    -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=${API_KEY}")

  if [[ $(echo "$token_request" | jq -r '.errorCode // empty') != "" ]]; then
    echo "ERROR: IAM token request failed."
    [[ $attempt -lt $MAX_ATTEMPTS ]] && { echo "Retrying in ${RETRY_DELAY}s..."; sleep $RETRY_DELAY; continue; }
    exit 1
  fi

  token=$(echo "$token_request" | jq -r '.access_token // empty')
  if [[ -z "$token" ]]; then
    echo "ERROR: IAM access token could not be retrieved."
    [[ $attempt -lt $MAX_ATTEMPTS ]] && { echo "Retrying in ${RETRY_DELAY}s..."; sleep $RETRY_DELAY; continue; }
    exit 1
  fi
  echo "OK: IAM token obtained"

  echo "--- Listing COS objects ---"
  echo "  List URL: ${LIST_URL}"

  list_response=$(curl -sS -H "Authorization: bearer $token" "${LIST_URL}")
  curl_status=$?
  if [[ $curl_status -ne 0 ]]; then
    echo "ERROR: Failed to list wheels from COS. curl exit code: ${curl_status}"
    [[ $attempt -lt $MAX_ATTEMPTS ]] && { echo "Retrying in ${RETRY_DELAY}s..."; sleep $RETRY_DELAY; continue; }
    exit 1
  fi

  if echo "$list_response" | grep -q "<Error>"; then
    echo "ERROR: COS list request returned an error response:"
    echo "$list_response"
    [[ $attempt -lt $MAX_ATTEMPTS ]] && { echo "Retrying in ${RETRY_DELAY}s..."; sleep $RETRY_DELAY; continue; }
    exit 1
  fi

  echo "  POWERCORE_WHEEL_VERSION: ${POWERCORE_VERSION}"

  listed_keys=$(printf '%s\n' "$list_response" \
    | grep -oE '<Key>[^<]+</Key>' \
    | sed -e 's#<Key>##' -e 's#</Key>##')

  required_wheels=(
    powercore_installer
    powercore_config
    powercore_database
    powercore_preprocess
    powercore_shallow_scan
    powercore_deep_scan
    powercore_postprocess
    powercore_bookkeeping
    powercore_workflow
  )

  matched_keys=""
  missing_wheel=false
  for wheel_name in "${required_wheels[@]}"; do
    wheel_key="${wheel_name}-${POWERCORE_VERSION}-py3-none-any.whl"
    if ! printf '%s\n' "$listed_keys" | grep -Fxq "$wheel_key"; then
      echo "ERROR: Required PowerCore wheel was not found in COS: ${wheel_key}"
      missing_wheel=true
      break
    fi
    matched_keys+="${wheel_key}"$'\n'
  done

  if [[ "${missing_wheel}" == "true" ]]; then
    [[ $attempt -lt $MAX_ATTEMPTS ]] && { echo "Retrying in ${RETRY_DELAY}s..."; sleep $RETRY_DELAY; continue; }
    exit 1
  fi

  echo "--- Downloading required PowerCore wheels for version ${POWERCORE_VERSION} ---"
  mkdir -p powercore-wheels
  download_failed=false
  while IFS= read -r wheel_key; do
    [[ -z "$wheel_key" ]] && continue
    echo "  Downloading: ${wheel_key}"
    if ! curl -fsS -H "Authorization: bearer $token" \
      -o "powercore-wheels/$(basename "$wheel_key")" \
      "${BUCKET_URL}/${wheel_key}"; then
      echo "ERROR: Failed to download wheel '${wheel_key}'"
      download_failed=true
      break
    fi
    echo "    OK: $(ls -lh "powercore-wheels/$(basename "$wheel_key")" | awk '{print $5}')"
  done <<< "$matched_keys"

  if [[ "${download_failed}" == "true" ]]; then
    [[ $attempt -lt $MAX_ATTEMPTS ]] && { echo "Retrying in ${RETRY_DELAY}s..."; sleep $RETRY_DELAY; continue; }
    exit 1
  fi

  echo "--- Wheel download complete ---"
  exit 0
done
