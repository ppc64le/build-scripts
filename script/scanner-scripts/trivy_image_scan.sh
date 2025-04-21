#!/bin/bash -e

image_name=$IMAGE_NAME
build_docker=$BUILD_DOCKER

if [ $build_docker == true ];then
	TRIVY_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
	wget https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VERSION#v}_Linux-PPC64LE.tar.gz
	tar -xzf trivy_${TRIVY_VERSION#v}_Linux-PPC64LE.tar.gz
        chmod +x trivy
        sudo mv trivy /usr/bin
	echo "Executing trivy scanner"
	sudo trivy -q image --timeout 30m -f json ${image_name} > trivy_image_vulnerabilities_results.json
	sudo trivy -q image --timeout 30m -f cyclonedx ${image_name} > trivy_image_sbom_results.cyclonedx
 fi

