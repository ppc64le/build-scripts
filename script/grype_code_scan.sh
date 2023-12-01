#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
actual_package_name=$(awk -F'/' 'tolower($0) ~ /^# source repo.*github.com/{sub(/\.git/, "", $NF); print $NF}' $PKG_DIR_PATH$BUILD_SCRIPT)

cd package-cache

if [ $validate_build_script == true ];then
     wget https://github.com/anchore/grype/releases/download/v0.67.0/grype_0.67.0_linux_ppc64le.tar.gz
     tar -xf grype_0.67.0_linux_ppc64le.tar.gz
     chmod +x grype
     sudo mv grype /usr/bin
                                
     sudo grype -q -o cyclonedx-json dir:${actual_package_name} > grype_source_sbom_results.json
     #curl -s -k -u ${env.dockerHubUser}:${env.dockerHubPassword} --upload-file grype_source_sbom_results.json ${url_prefix}/source/Grype_sbom_results.json
     cat grype_source_sbom_results.json
                                
     sudo grype -q -o json dir:${actual_package_name} > grype_source_vulnerabilities_results.json
     #curl -s -k -u ${env.dockerHubUser}:${env.dockerHubPassword} --upload-file grype_source_vulnerabilities_results.json ${url_prefix}/source/Grype_vulnerabilities_results.json
     cat grype_source_vulnerabilities_results.json
     token_request=$(curl -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$ibm_cos_api")
     token=$(echo "$token_request" | jq -r '.access_token')
     curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: text/plain" -d @grype_source_sbom_results.json "https://s3.au-syd.cloud-object-storage.appdomain.cloud/currency-automation-toolci-bucket/$PACKAGE_NAME/$VERSION/grype_source_sbom_results.json"
     curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: text/plain" -d @grype_source_vulnerabilities_results.json "https://s3.au-syd.cloud-object-storage.appdomain.cloud/currency-automation-toolci-bucket/$PACKAGE_NAME/$VERSION/grype_source_vulnerabilities_results.json"
fi
