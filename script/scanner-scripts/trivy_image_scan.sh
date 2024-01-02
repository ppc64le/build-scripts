#!/bin/bash -e

image_name=$IMAGE_NAME
build_docker=$BUILD_DOCKER

cd package-cache

if [ $build_docker == true ];then
	wget https://github.com/aquasecurity/trivy/releases/download/v0.45.0/trivy_0.45.0_Linux-PPC64LE.tar.gz
	tar -xf trivy_0.45.0_Linux-PPC64LE.tar.gz
        chmod +x trivy
        sudo mv trivy /usr/bin
	sudo trivy -q image --timeout 30m -f json ${image_name} > trivy_image_vulnerabilities_results.json
	sudo trivy -q image --timeout 30m -f cyclonedx ${image_name} > trivy_image_sbom_results.cyclonedx
 fi


