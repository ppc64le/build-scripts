#!/bin/bash -e

token_request=$(curl -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$GHA_CURRENCY_SERVICE_ID_API_KEY")

if [[ $(echo "$token_request" | jq -r '.errorCode') == "null" ]]; then
    token=$(echo "$token_request" | jq -r '.access_token')
    echo "Downloading $1 from COS..."
    curl -X GET -H "Authorization: bearer $token" \
      -o $1 "https://s3.us.cloud-object-storage.appdomain.cloud/ose-power-toolci-bucket-production/$PACKAGE_NAME/$VERSION/$1"
    echo "Download completed: $1"
else
    echo "Error: Token request failed. Response: $token_request"
    exit 1
fi
