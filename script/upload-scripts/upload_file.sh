#!/bin/bash -e

token_request=$(curl -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$travis_currency_service_id_api_key")

#token=$(echo "$token_request" | jq -r '.access_token')
#curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/gzip" -T $1 "https://s3.au-syd.cloud-object-storage.appdomain.cloud/ose-power-toolci-bucket/$PACKAGE_NAME/$VERSION/$1"

# Check if the token request was successful based on the presence of 'errorCode'
if [[ $(echo "$token_request" | jq -r '.errorCode') == "null" ]]; then
    token=$(echo "$token_request" | jq -r '.access_token')
    
    # curl command for uploading the file
    response=$(curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/gzip" -T $1 "https://s3.us-east.cloud-object-storage.appdomain.cloud/ose-power-toolci-bucket/$PACKAGE_NAME/$VERSION/$1")

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
