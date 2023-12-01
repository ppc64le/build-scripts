#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
actual_package_name=$(awk -F'/' 'tolower($0) ~ /^# source repo.*github.com/{sub(/\.git/, "", $NF); print $NF}' $PKG_DIR_PATH$BUILD_SCRIPT)

cd package-cache

if [ $validate_build_script == true ];then
	echo "downloading trivy package"
	wget https://github.com/aquasecurity/trivy/releases/download/v0.40.0/trivy_0.40.0_Linux-PPC64LE.tar.gz
 	ls -ltr
	tar -xf trivy_0.40.0_Linux-PPC64LE.tar.gz
        chmod +x trivy
        sudo mv trivy /usr/bin
	sudo trivy -q fs --timeout 30m -f json ${actual_package_name} > trivy_source_vulnerabilities_results.json
 	#curl -s -k -u ${env.dockerHubUser}:${env.dockerHubPassword} --upload-file trivy_source_vulnerabilities_results.json ${url_prefix}/source/Trivy_vulnerabilities_results.json
	echo "printing the trivy_source_vulnerabilities_results.json"
  	echo "------------------------------------------"
   	echo
 	cat trivy_source_vulnerabilities_results.json
	sudo trivy -q fs --timeout 30m -f cyclonedx ${actual_package_name} > trivy_source_sbom_results.cyclonedx
	#curl -s -k -u ${env.dockerHubUser}:${env.dockerHubPassword} --upload-file trivy_source_sbom_results.cyclonedx ${url_prefix}/source/Trivy_sbom_results.json
 	echo "printing the trivy_source_sbom_results.cyclonedx"
  	echo "-------------------------"
   	echo
  	cat trivy_source_sbom_results.cyclonedx
   	token_request=$(curl -X POST https://iam.cloud.ibm.com/identity/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: application/json" \
  -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=$ibm_cos_api")
       	token=$(echo "$token_request" | jq -r '.access_token')
      	curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: text/plain" -d @trivy_source_vulnerabilities_results.json "https://s3.au-syd.cloud-object-storage.appdomain.cloud/currency-automation-toolci-bucket/$PACKAGE_NAME/$VERSION/trivy_source_vulnerabilities_results.json"
        curl -X PUT -H "Authorization: bearer $token" -H "Content-Type: text/plain" -d @trivy_source_sbom_results.cyclonedx "https://s3.au-syd.cloud-object-storage.appdomain.cloud/currency-automation-toolci-bucket/$PACKAGE_NAME/$VERSION/trivy_source_sbom_results.cyclonedx"
 fi

