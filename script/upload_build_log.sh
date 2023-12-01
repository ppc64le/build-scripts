#!/bin/bash -e

token_request=$(curl -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$ibm_cos_api")

token=$(echo "$token_request" | jq -r '.access_token')
curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: text/plain" -d @build_log.gz "https://s3.au-syd.cloud-object-storage.appdomain.cloud/currency-automation-toolci-bucket/$PACKAGE_NAME/$VERSION/build_log.gz"
