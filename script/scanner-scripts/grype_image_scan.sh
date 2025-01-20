#!/bin/bash -e

image_name=$IMAGE_NAME
build_docker=$BUILD_DOCKER

if [ $build_docker == true ];then
	 wget https://github.com/anchore/grype/releases/download/v0.67.0/grype_0.67.0_linux_ppc64le.tar.gz
	 tar -xf grype_0.67.0_linux_ppc64le.tar.gz
         chmod +x grype
         sudo mv grype /usr/bin
	 echo "Executing grype scanner"
         sudo grype -q -s AllLayers -o cyclonedx-json ${image_name} > grype_image_sbom_results.json
         sudo grype -q -s AllLayers -o json ${image_name} > grype_image_vulnerabilities_results.json
fi

