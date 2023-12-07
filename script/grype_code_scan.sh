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
     sudo grype -q -o json dir:${actual_package_name} > grype_source_vulnerabilities_results.json
fi
