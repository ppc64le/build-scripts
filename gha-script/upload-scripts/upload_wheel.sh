#!/bin/bash -e

#variables
WHEEL_FILE=$1
WHEEL_SHA256=$2

# Validate SHA256
if [ -z "$WHEEL_SHA256" ]; then
  echo "Error: SHA256 value is required."
  exit 1
fi

echo
echo "Uploading $WHEEL_FILE with SHA256 $WHEEL_SHA256"
echo 

token_request=$(curl -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$GHA_CURRENCY_SERVICE_ID_API_KEY")

#token=$(echo "$token_request" | jq -r '.access_token')
#curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/gzip" -T $1 "https://s3.au-syd.cloud-object-storage.appdomain.cloud/currency-automation-toolci-bucket/$PACKAGE_NAME/$VERSION/$1"

# Check if the token request was successful based on the presence of 'errorCode'
if [[ $(echo "$token_request" | jq -r '.errorCode') == "null" ]]; then
    token=$(echo "$token_request" | jq -r '.access_token')
    
    # curl command for uploading the file
    #response=$(curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/octet-stream" -T $1 "https://s3.us.cloud-object-storage.appdomain.cloud/ose-power-artifacts-prod/$PACKAGE_NAME/$VERSION/$1")
    response=$(curl -X PUT \
        -H "Authorization: bearer $token" \
        -H "Content-Type: application/octet-stream" \
        -H "x-amz-meta-sha256: $WHEEL_SHA256" \
        -T $WHEEL_FILE \
        "https://s3.us.cloud-object-storage.appdomain.cloud/ose-power-artifacts-production/$PACKAGE_NAME/$VERSION/$WHEEL_FILE")

    # Check if the PUT request was successful based on the absence of an <Error> block
    if ! echo "$response" | grep -q "<Error>"; then
        echo "File successfully uploaded."
    else
        # Handle PUT request failure
        echo "Error: PUT request failed. Response: $response"
        exit 1
    fi    
else
    # Handle token request failure
    echo "Error: Token request failed. Response: $token_request"
    exit 1
fi
