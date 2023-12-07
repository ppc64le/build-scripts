#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
actual_package_name=$(awk -F'/' 'tolower($0) ~ /^# source repo.*github.com/{sub(/\.git/, "", $NF); print $NF}' $PKG_DIR_PATH$BUILD_SCRIPT)

cd package-cache

if [ $validate_build_script == true ];then
	wget https://github.com/aquasecurity/trivy/releases/download/v0.45.0/trivy_0.45.0_Linux-PPC64LE.tar.gz
	tar -xf trivy_0.45.0_Linux-PPC64LE.tar.gz
        chmod +x trivy
        sudo mv trivy /usr/bin
	sudo trivy -q fs --timeout 30m -f json ${actual_package_name} > trivy_source_vulnerabilities_results.json
	sudo trivy -q fs --timeout 30m -f cyclonedx ${actual_package_name} > trivy_source_sbom_results.cyclonedx	
 fi

