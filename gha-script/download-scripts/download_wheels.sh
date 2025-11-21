#!/bin/bash -e
 
validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE
mkdir -p package-cache/wheels
 
token_request=$(curl -s -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$GHA_CURRENCY_SERVICE_ID_API_KEY")
 
if [[ $(echo "$token_request" | jq -r '.errorCode') == "null" ]]; then
    token=$(echo "$token_request" | jq -r '.access_token')
    bucket_url="https://s3.us.cloud-object-storage.appdomain.cloud/ose-power-artifacts-production"
 
    echo "Fetching wheel list from COS..."
    echo "Checking prefix: $PACKAGE_NAME/$VERSION/"
    curl -s -H "Authorization: bearer $token" \
      "$bucket_url?list-type=2&prefix=$PACKAGE_NAME/$VERSION/" \
      | grep -oP '(?<=<Key>)[^<]*\.whl' > wheels_list.txt
 
    # If none found, dump available keys for debugging
    if [[ ! -s wheels_list.txt ]]; then
    
        curl -s -H "Authorization: bearer $token" \
          "$bucket_url?list-type=2&prefix=$PACKAGE_NAME/" \
          | grep -oP '(?<=<Key>)[^<]*' || true
        exit 1
    fi
 
    cat wheels_list.txt
    echo "---------------------------------------------------------"
 
    while read -r wheel; do
      echo "Downloading wheel: $wheel"
      curl -s -H "Authorization: bearer $token" \
        -o "package-cache/wheels/$(basename "$wheel")" \
        "$bucket_url/$wheel"
    done < wheels_list.txt
 
    echo "---------------------------------------------------------"
    ls -lh package-cache/wheels
    echo "---------------------------------------------------------"
 
else
    echo "Error: Token request failed. Response: $token_request"
    exit 1
fi
