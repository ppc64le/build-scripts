#!/bin/bash -xe

version="$VERSION"
package_dirpath="$PKG_DIR_PATH"
config_file="build_info.json"
image_name=$IMAGE_NAME
build_docker=$BUILD_DOCKER

cd $package_dirpath

if [ $build_docker == true ];then
        echo "downloading grype package"
	 wget https://github.com/anchore/grype/releases/download/v0.62.1/grype_0.62.1_linux_ppc64le.tar.gz
         ls -ltr
	 tar -xf grype_0.62.1_linux_ppc64le.tar.gz
         chmod +x grype
         sudo mv grype /usr/bin
         sudo grype -q -s AllLayers -o cyclonedx-json ${image_name} > grype_sbom_results.json
	 echo "printing  grype_sbom_results.json"
	 echo "---------------------------------"
	 echo
	 cat grype_sbom_results.json
       #  curl -s -k -u ${env.dockerHubUser}:${env.dockerHubPassword} --upload-file grype_sbom_results.json ${url_prefix}/Grype_sbom_results.json
         sudo grype -q -s AllLayers -o json ${image_name} > grype_vulnerabilities_results.json
         echo "printing grype_vulnerabilities_results.json"
	 echo "-------------------------------------------"
	 echo
	 cat grype_vulnerabilities_results.json
	 ls -ltr | grep "grype"
       #  curl -s -k -u ${env.dockerHubUser}:${env.dockerHubPassword} --upload-file grype_vulnerabilities_results.json ${url_prefix}/Grype_vulnerabilities_results.json
fi

