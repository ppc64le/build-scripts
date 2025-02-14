#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE
cd package-cache

if [ $validate_build_script == true ];then
      wget https://github.com/anchore/syft/releases/download/v0.90.0/syft_0.90.0_linux_ppc64le.tar.gz
      tar -xf syft_0.90.0_linux_ppc64le.tar.gz
      chmod +x syft
      sudo mv syft /usr/bin                           
      echo "Executing syft scanner"
      sudo syft -q -o cyclonedx-json dir:${cloned_package} > syft_source_sbom_results.json
      #cat syft_source_sbom_results.json
fi

