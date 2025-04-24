#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE
cd package-cache

if [ $validate_build_script == true ];then
      SYFT_VERSION=$(curl -s https://api.github.com/repos/anchore/syft/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
      wget https://github.com/anchore/syft/releases/download/$SYFT_VERSION/syft_${SYFT_VERSION#v}_linux_ppc64le.tar.gz
      tar -xzf syft_${SYFT_VERSION#v}_linux_ppc64le.tar.gz
      chmod +x syft
      sudo mv syft /usr/bin                           
      echo "Executing syft scanner"
      sudo syft -q -o cyclonedx-json dir:${cloned_package} > syft_source_sbom_results.json
      #cat syft_source_sbom_results.json
fi
