# ----------------------------------------------------------------------------
#
# Package         : tektoncd/pipeline 
# Version         : v0.15.0
# Source repo     : https://github.com/tektoncd/pipeline.git
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Amit Baheti <aramswar@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
# ----------------------------------------------------------------------------
# Prerequisites:
#
# Docker 17.05 or later must be installed and running.
#
# Go version 1.13.1 or later must be installed.
#
# Kubectl version 1.15.0 or later must be installed.
# Note: For kubectl version below 1.15.0, the “tkn” plugin may not be identified by kubectl. 
# Hence, it is recommended to use 1.15.0 or later versions of kubectl.
#
# ----------------------------------------------------------------------------

set -e
yum update -y
yum install git -y


export GOPATH=${HOME}/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export GO111MODULE=auto

#Offical ko repo doesnot support multiplatform build
#PR: https://github.com/google/ko/pull/38
#Once PR is merged, we can use "go get -u github.com/google/ko/cmd/ko"
mkdir -p ${GOPATH}/src/github.com/google && cd $_
git clone -b multi-platform-wip https://github.com/jonjohnsonjr/ko.git
cd ko/cmd/ko/
go install

mkdir -p ${GOPATH}/src/github.com/tektoncd && cd $_
git clone --branch v0.15.0 https://github.com/tektoncd/pipeline.git
cd pipeline

#Download base dockerfiles
curl -o images/Dockerfile.build-base-ubi https://raw.githubusercontent.com/ppc64le/build-scripts/master/t/tektoncd-components/base-dockerfiles/Dockerfile.build-base-ubi
curl -o images/Dockerfile.busybox-ubi https://raw.githubusercontent.com/ppc64le/build-scripts/master/t/tektoncd-components/base-dockerfiles/Dockerfile.busybox-ubi
curl -o images/Dockerfile.cloud-sdk-docker-ubi https://raw.githubusercontent.com/ppc64le/build-scripts/master/t/tektoncd-components/base-dockerfiles/Dockerfile.cloud-sdk-docker-ubi

#Build required base images
docker build -t build/build-base:latest -f images/Dockerfile.build-base-ubi .
docker build -t ppc64le/busybox:ubi -f images/Dockerfile.busybox-ubi .
docker build -t cloud-sdk-docker:ubi -f images/Dockerfile.cloud-sdk-docker-ubi .


#Changes in .ko.yaml file
echo 'baseImageOverrides:
  github.com/tektoncd/pipeline/cmd/creds-init: localhost:5000/build/build-base:latest
  github.com/tektoncd/pipeline/cmd/git-init: localhost:5000/build/build-base:latest
  github.com/tektoncd/pipeline/cmd/entrypoint: localhost:5000/ppc64le/busybox:ubi # image should have shell in $PATH
  github.com/tektoncd/pipeline/cmd/kubeconfigwriter: localhost:5000/build/build-base:latest # image should have gsutil in $PATH
  github.com/tektoncd/pipeline/cmd/controller: localhost:5000/build/build-base:latest # image should have gsutil in $PATH
  github.com/tektoncd/pipeline/cmd/imagedigestexporter: localhost:5000/build/build-base:latest # image should have gsutil in $PATH
  github.com/tektoncd/pipeline/cmd/pullrequest-init: localhost:5000/build/build-base:latest # image should have gsutil in $PATH
  github.com/tektoncd/pipeline/cmd/webhook: localhost:5000/build/build-base:latest # image should have gsutil in $PATH
  github.com/tektoncd/pipeline/cmd/nop: localhost:5000/build/build-base:latest # image should have gsutil in $PATH
' >.ko.yaml

#Create a local registry & push required base images 
docker run -d --name registry -p 5000:5000 ppc64le/registry:2

#Push images
docker tag build/build-base:latest localhost:5000/build/build-base:latest
docker push localhost:5000/build/build-base:latest
docker tag ppc64le/busybox:ubi localhost:5000/ppc64le/busybox:ubi
docker push localhost:5000/ppc64le/busybox:ubi
docker tag cloud-sdk-docker:ubi localhost:5000/cloud-sdk-docker:ubi
docker push localhost:5000/cloud-sdk-docker:ubi


#Build & publish tektoncd-pipeline images
export KO_DOCKER_REPO=localhost:5000/ko.local
ko publish --platform=linux/ppc64le ./cmd/creds-init/ >> output_images
ko publish --platform=linux/ppc64le ./cmd/git-init >> output_images
ko publish --platform=linux/ppc64le ./cmd/entrypoint/ >> output_images
ko publish --platform=linux/ppc64le ./cmd/kubeconfigwriter/ >> output_images
ko publish --platform=linux/ppc64le ./cmd/controller/ >> output_images
ko publish --platform=linux/ppc64le ./cmd/imagedigestexporter/ >> output_images
ko publish --platform=linux/ppc64le ./cmd/pullrequest-init/ >> output_images
ko publish --platform=linux/ppc64le ./cmd/webhook/ >> output_images
ko publish --platform=linux/ppc64le ./cmd/nop/ >> output_images



# Uncomment below lines for Openshift 4.3 - these are for creating imagestreams
# oc new-project local-images
# oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=local-images 
# HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
# input="output_images"
# while IFS= read -r line
# do
#   docker pull $line
#   image=`echo $line | awk -F'/' '{print $3}' | awk -F'@' '{print $1}'`
#   docker tag $line $HOST/local-images/$image
#   docker push $HOST/local-images/$image
# done < "$input"

