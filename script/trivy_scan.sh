#!/bin/bash -xe

version="$VERSION"
package_dirpath="$PKG_DIR_PATH"
config_file="build_info.json"
image_name=$IMAGE_NAME
build_docker=$BUILD_DOCKER

cd $package_dirpath

if [ $build_docker == true ];then
	echo "downloading trivy package"
	wget https://github.com/aquasecurity/trivy/releases/download/v0.40.0/trivy_0.40.0_Linux-PPC64LE.tar.gz
 	ls -ltr
	tar -xf trivy_0.40.0_Linux-PPC64LE.tar.gz
        chmod +x trivy
        sudo mv trivy /usr/bin
	sudo trivy -q image --timeout 10m -f json ${image_name} > vulnerabilities_results.json
 	echo "printing the vulnerabilities_results.json"
  	echo "------------------------------------------"
   	echo
 	cat vulnerabilities_results.json
	#curl -s -k -u ${env.dockerHubUser}:${env.dockerHubPassword} --upload-file vulnerabilities_results.json ${url_prefix}/Trivy_vulnerabilities_results.json
	sudo trivy -q image --timeout 10m ${image_name} > vulnerabilities_results.txt
 	echo "printing the vulnerabilities_results.txt"
  	echo "----------------------------------------"
   	echo
  	cat vulnerabilities_results.txt
	#curl -s -k -u ${env.dockerHubUser}:${env.dockerHubPassword} --upload-file vulnerabilities_results.txt ${url_prefix}/Trivy_vulnerabilities_results.txt
	sudo trivy -q image --timeout 10m -f cyclonedx ${image_name} > sbom_results.cyclonedx
 	echo "printing the sbom_results"
  	echo "-------------------------"
   	echo
  	cat sbom_results.cyclonedx
	#curl -s -k -u ${env.dockerHubUser}:${env.dockerHubPassword} --upload-file sbom_results.cyclonedx ${url_prefix}/Trivy_sbom_results.json
	grep -B2 "Total: " vulnerabilities_results.txt > vulnerabilities_summary.txt
 	echo "printing the vulnerabilities_summary.txt"
  	echo "----------------------------------------"
   	echo
  	cat vulnerabilities_summary.txt
   	pwd
  	ls -ltr | grep "vulner"
	#curl -s -k -u ${env.dockerHubUser}:${env.dockerHubPassword} --upload-file vulnerabilities_summary.txt ${url_prefix}/Trivy_vulnerability_summary.txt
 fi


