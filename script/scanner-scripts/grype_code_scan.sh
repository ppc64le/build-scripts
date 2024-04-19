#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE

cd package-cache

if [ $validate_build_script == true ];then
     wget https://github.com/anchore/grype/releases/download/v0.67.0/grype_0.67.0_linux_ppc64le.tar.gz
     tar -xf grype_0.67.0_linux_ppc64le.tar.gz
     chmod +x grype
     sudo mv grype /usr/bin                      
     echo "Executing Grype scanner"
     sudo grype -q -o cyclonedx-json dir:${cloned_package} > grype_source_sbom_results.json    
     #cat grype_source_sbom_results.json 
     sudo grype -q -o json dir:${cloned_package} > grype_source_vulnerabilities_results.json
     #cat grype_source_vulnerabilities_results.json
fi
