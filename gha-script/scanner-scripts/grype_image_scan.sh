#!/bin/bash -e
image_name="icr.io/ose4power-packages-production/$package_name-ppc64le:$VERSION"
echo "-------------------------------------------------"
echo "Image Name: $image_name"
build_docker=$BUILD_DOCKER

if [ $build_docker == true ];then
	 GRYPE_VERSION=$(curl -s https://api.github.com/repos/anchore/grype/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
	 wget https://github.com/anchore/grype/releases/download/$GRYPE_VERSION/grype_${GRYPE_VERSION#v}_linux_ppc64le.tar.gz
	 tar -xzf grype_${GRYPE_VERSION#v}_linux_ppc64le.tar.gz
         chmod +x grype
         sudo mv grype /usr/bin
	 echo "Executing grype scanner"
         sudo grype -q -s AllLayers -o cyclonedx-json ${image_name} > grype_image_sbom_results.json
         sudo grype -q -s AllLayers -o json ${image_name} > grype_image_vulnerabilities_results.json
fi
