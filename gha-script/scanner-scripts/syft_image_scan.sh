#!/bin/bash -e
image_name="icr.io/ose4power-packages-production/$package_name-ppc64le:$VERSION"
echo "-------------------------------------------------"
echo "Image Name: $image_name"
build_docker=$BUILD_DOCKER

echo "$GHA_CURRENCY_SERVICE_ID_API_KEY" | docker login -u iamapikey --password-stdin icr.io

if [ $build_docker == true ];then
        SYFT_VERSION=$(curl -s https://api.github.com/repos/anchore/syft/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
        wget https://github.com/anchore/syft/releases/download/$SYFT_VERSION/syft_${SYFT_VERSION#v}_linux_ppc64le.tar.gz
        tar -xzf syft_${SYFT_VERSION#v}_linux_ppc64le.tar.gz
        chmod +x syft
        sudo mv syft /usr/bin  
        echo "Executing syft scanner"
        sudo syft -q -s AllLayers -o cyclonedx-json ${image_name} > syft_image_sbom_results.json
fi
