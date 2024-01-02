#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
actual_package_name=$(awk -F'/' 'tolower($0) ~ /^# source repo.*github.com/{sub(/\.git/, "", $NF); print $NF}' $PKG_DIR_PATH$BUILD_SCRIPT)

cd package-cache

if [ $validate_build_script == true ];then
      wget https://github.com/anchore/syft/releases/download/v0.90.0/syft_0.90.0_linux_ppc64le.tar.gz
      tar -xf syft_0.90.0_linux_ppc64le.tar.gz
      chmod +x syft
      sudo mv syft /usr/bin                           
      sudo syft -q -o cyclonedx-json dir:${actual_package_name} > syft_source_sbom_results.json
fi

