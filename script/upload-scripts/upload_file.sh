#!/bin/bash -e
export IS_SETUP=${IS_SETUP:-"prod"}

if [ "$IS_SETUP" = "dev" ] || [ "$IS_SETUP" = "staging" ];
then 
    token_request=$(curl -X POST https://iam.cloud.ibm.com/identity/token \
    -H "content-type: application/x-www-form-urlencoded" \
    -H "accept: application/json" \
    -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$travis_currency_service_id_api_key_dev")

    #token=$(echo "$token_request" | jq -r '.access_token')
    #curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/gzip" -T $1 "https://s3.au-syd.cloud-object-storage.appdomain.cloud/ose-power-toolci-bucket/$PACKAGE_NAME/$VERSION/$1"

    # Check if the token request was successful based on the presence of 'errorCode'
    if [[ $(echo "$token_request" | jq -r '.errorCode') == "null" ]]; then
        token=$(echo "$token_request" | jq -r '.access_token')
        
        # curl command for uploading the file
        response=$(curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/gzip" -T $1 "https://s3.us.cloud-object-storage.appdomain.cloud/ose-power-toolci-bucket-stag/$PACKAGE_NAME/$VERSION/$1")

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
elif [ "$IS_SETUP" = "pen" ]; then
    token_request=$(curl -X POST https://iam.cloud.ibm.com/identity/token \
    -H "content-type: application/x-www-form-urlencoded" \
    -H "accept: application/json" \
    -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$travis_currency_service_id_api_key_pen")

    if [[ $(echo "$token_request" | jq -r '.errorCode') == "null" ]]; then
        token=$(echo "$token_request" | jq -r '.access_token')
        response=$(curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/octet-stream" -T $1 "https://s3.us.cloud-object-storage.appdomain.cloud/ose-power-toolci-bucket-pentesting/$PACKAGE_NAME/$VERSION/$1")

        if ! echo "$response" | grep -q "<Error>"; then
            echo "File successfully uploaded."
        else
            echo "Error: PUT request failed. Response: $response"
            exit 1
        fi
    else
        echo "Error: Token request failed. Response: $token_request"
        exit 1
    fi
else
    token_request=$(curl -X POST https://iam.cloud.ibm.com/identity/token \
    -H "content-type: application/x-www-form-urlencoded" \
    -H "accept: application/json" \
    -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$travis_currency_service_id_api_key_prod")

    #token=$(echo "$token_request" | jq -r '.access_token')
    #curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/gzip" -T $1 "https://s3.au-syd.cloud-object-storage.appdomain.cloud/ose-power-toolci-bucket/$PACKAGE_NAME/$VERSION/$1"

    # Check if the token request was successful based on the presence of 'errorCode'
    if [[ $(echo "$token_request" | jq -r '.errorCode') == "null" ]]; then
        token=$(echo "$token_request" | jq -r '.access_token')
        
        # curl command for uploading the file
        response=$(curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: application/gzip" -T $1 "https://s3.us.cloud-object-storage.appdomain.cloud/ose-power-toolci-bucket-production/$PACKAGE_NAME/$VERSION/$1")

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
fi
