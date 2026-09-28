#!/usr/bin/env bash
# generate-powercore-config.sh — Fetch the staging PowerCore config secret from
# IBM Cloud Secrets Manager and write powercore-config.env to the current directory.
#
# Usage:
#   ./generate-powercore-config.sh \
#       --api-key    <IAM_API_KEY> \
#       --version    <POWERCORE_WHEEL_VERSION> \
#       --gh-token   <GITHUB_TOKEN> \
#       --image-tag  <ICR_IMAGE_TAG>
#
# Environment variable equivalents:
#   IAM_API_KEY / IBMCLOUD_API_KEY / GHA_CURRENCY_SERVICE_ID_API_KEY
#   POWERCORE_WHEEL_VERSION / POWERCORE_VERSION
#   GITHUB_TOKEN / GH_TOKEN
#   ICR_IMAGE_TAG
#
# Outputs:
#   powercore-config.env   written to the current working directory
# Tested on UBI9
set -euo pipefail

# ── Secrets Manager configuration ────────────────────────────────────────────
SM_INSTANCE_ID="${SM_INSTANCE_ID:?SM_INSTANCE_ID environment variable is required}"
SM_SECRET_ID="${SM_SECRET_ID:?SM_SECRET_ID environment variable is required}"
SM_REGION="us-east"

# ── Defaults from environment ─────────────────────────────────────────────────
API_KEY="${IBMCLOUD_API_KEY:-${IAM_API_KEY:-${GHA_CURRENCY_SERVICE_ID_API_KEY:-}}}"
POWERCORE_VERSION_INPUT="${POWERCORE_VERSION:-${POWERCORE_WHEEL_VERSION:-}}"
GITHUB_TOKEN_INPUT="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
ICR_IMAGE_TAG_INPUT="${ICR_IMAGE_TAG:-}"

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key)    API_KEY="$2";                  shift 2 ;;
    --version)    POWERCORE_VERSION_INPUT="$2";  shift 2 ;;
    --gh-token)   GITHUB_TOKEN_INPUT="$2";       shift 2 ;;
    --image-tag)  ICR_IMAGE_TAG_INPUT="$2";      shift 2 ;;
    -h|--help)
      echo "Usage: $0 --api-key <KEY> --version <VERSION> --gh-token <TOKEN> [--image-tag <TAG>]"
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1"
      exit 1
      ;;
  esac
done

# ── Validation ────────────────────────────────────────────────────────────────
if [[ -z "${API_KEY}" ]]; then
  echo "ERROR: IAM API key is required (--api-key or set IAM_API_KEY)"
  exit 1
fi
if [[ -z "${POWERCORE_VERSION_INPUT}" ]]; then
  echo "ERROR: PowerCore version is required (--version or set POWERCORE_WHEEL_VERSION)"
  exit 1
fi
if [[ -z "${GITHUB_TOKEN_INPUT}" ]]; then
  echo "ERROR: GitHub token is required (--gh-token or set GITHUB_TOKEN)"
  exit 1
fi

# ── Step 1: Authenticate ──────────────────────────────────────────────────────
echo "=== 1. Authenticating with IBM Cloud IAM ==="
token_request=$(curl -sS -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=${API_KEY}")

if [[ $(echo "${token_request}" | jq -r '.errorCode // empty') != "" ]]; then
  echo "ERROR: IAM token request failed."
  exit 1
fi

token=$(echo "${token_request}" | jq -r '.access_token // empty')
if [[ -z "${token}" ]]; then
  echo "ERROR: IAM access token could not be retrieved."
  exit 1
fi
echo "OK: IAM access token obtained"

# ── Step 2: Fetch secret ──────────────────────────────────────────────────────
echo "=== 2. Fetching secret from Secrets Manager ==="
SM_API_URL="https://${SM_INSTANCE_ID}.${SM_REGION}.secrets-manager.appdomain.cloud/api/v2/secrets/${SM_SECRET_ID}"
echo "  Secret ID : ${SM_SECRET_ID} (powercore-config-secrets-staging)"
echo "  Instance  : ${SM_INSTANCE_ID} (${SM_REGION})"

secret_response=$(curl -sS -X GET "${SM_API_URL}" \
  -H "Authorization: Bearer ${token}" \
  -H "Accept: application/json")

if echo "${secret_response}" | grep -q '"errors"'; then
  echo "ERROR: Failed to retrieve secret from Secrets Manager:"
  echo "${secret_response}" | jq -r '.errors[]?.message // .' 2>/dev/null || echo "${secret_response}"
  exit 1
fi

# ── Step 3: Generate powercore-config.env ─────────────────────────────────────
echo "=== 3. Generating powercore-config.env ==="
python3 -c "
import json, sys

raw = sys.stdin.read()
doc = json.loads(raw)
version_input = sys.argv[1]

# Support multiple Secrets Manager KV response structures
kv_data = None
if 'data' in doc and isinstance(doc['data'], dict):
    if 'data' in doc['data'] and isinstance(doc['data']['data'], dict):
        kv_data = doc['data']['data']
    else:
        kv_data = doc['data']
elif 'resources' in doc and len(doc['resources']) > 0:
    res = doc['resources'][0]
    kv_data = res.get('secret_data') or res.get('data') or {}
elif 'secret_data' in doc and isinstance(doc['secret_data'], dict):
    kv_data = doc['secret_data']

if not kv_data or not isinstance(kv_data, dict):
    sys.stderr.write('ERROR: Could not parse key-value data from Secrets Manager response\n')
    sys.exit(1)

api_key_input   = sys.argv[3] if len(sys.argv) > 3 else ''
image_tag_input = sys.argv[4] if len(sys.argv) > 4 else ''

# Inject / override version and token
kv_data['POWERCORE_WHEEL_VERSION'] = version_input
if len(sys.argv) > 2 and sys.argv[2]:
    kv_data['GITHUB_TOKEN'] = sys.argv[2]

# Map the caller's API key to all downstream service key variables
if api_key_input:
    kv_data['COS_API_KEY']        = api_key_input
    kv_data['ICR_API_KEY']        = api_key_input
    kv_data['IBMCLOUD_API_KEY']   = api_key_input
    kv_data['IAM_WRITER_API_KEY'] = api_key_input

# Inject image tag if provided
if image_tag_input:
    kv_data['ICR_IMAGE_TAG'] = image_tag_input

with open('powercore-config.env', 'w') as f:
    for k, v in kv_data.items():
        f.write(f'{k}={v}\n')
" "${POWERCORE_VERSION_INPUT}" "${GITHUB_TOKEN_INPUT}" "${API_KEY}" "${ICR_IMAGE_TAG_INPUT}" <<< "${secret_response}"

if [[ ! -f powercore-config.env ]]; then
  echo "ERROR: powercore-config.env was not generated"
  exit 1
fi

echo "  Generated powercore-config.env successfully."
echo "--- powercore-config.env (safe view — keys only) ---"
grep -E '^[A-Z_]+=' powercore-config.env | sed 's/=.*/=<hidden>/' || true
echo "--- done ---"
