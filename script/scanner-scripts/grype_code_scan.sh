#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE

cd package-cache

if [ $validate_build_script == true ];then
     GRYPE_VERSION=$(curl -s https://api.github.com/repos/anchore/grype/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
     wget https://github.com/anchore/grype/releases/download/$GRYPE_VERSION/grype_${GRYPE_VERSION#v}_linux_ppc64le.tar.gz
     tar -xzf grype_${GRYPE_VERSION#v}_linux_ppc64le.tar.gz
     chmod +x grype
     sudo mv grype /usr/bin 
     grype --version
     echo "Executing Grype scanner"
     sudo grype -q -o cyclonedx-json dir:${cloned_package} > grype_source_sbom_results.json    
     #cat grype_source_sbom_results.json 
     sudo grype -q -o json dir:${cloned_package} > grype_source_vulnerabilities_results.json
     #cat grype_source_vulnerabilities_results.json
fi
