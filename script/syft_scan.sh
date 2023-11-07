#!/bin/bash -xe

version="$VERSION"
packageDirPath="$PKG_DIR_PATH"
configFile="build_info.json"
imageName=$IMAGE_NAME
buildDocker=$BUILD_DOCKER

cd $packageDirPath


if [ $buildDocker == true ];then
        echo "downloading syft package"
        wget https://github.com/anchore/syft/releases/download/v0.60.3/syft_0.60.3_linux_ppc64le.tar.gz
        ls -ltr
        tar -xf syft_0.60.3_linux_ppc64le.tar.gz
        chmod +x syft
        sudo mv syft /usr/bin  
        sudo syft -q -s AllLayers -o cyclonedx-json ${imageName} > syft_sbom_results.json
	echo "printing the syft_sbom_results.json"
	echo "-----------------------------------"
	echo 
	cat syft_sbom_results.json
       # curl -s -k -u ${env.dockerHubUser}:${env.dockerHubPassword} --upload-file syft_sbom_results.json ${url_prefix}/Syft_sbom_results.json
fi

