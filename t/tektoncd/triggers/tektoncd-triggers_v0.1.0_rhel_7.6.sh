# ----------------------------------------------------------------------------
#
# Package         : tektoncd/triggers
# Version         : v0.1.0
# Source repo     : https://github.com/tektoncd/triggers.git
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
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
# Go version 1.12.0 or later must be installed.
# 
# For deployment:
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

#Install go packages
go get -u github.com/golang/dep/cmd/dep
#Offical ko repo doesnot support multiplatform build
#PR: https://github.com/google/ko/pull/38
#Once PR is merged, we can use "go get -u github.com/google/ko/cmd/ko"
mkdir -p ${GOPATH}/src/github.com/google&& cd $_
git clone -b multi-platform-wip https://github.com/jonjohnsonjr/ko.git
cd ko/cmd/ko/
go install

#Build tektoncd/triggers
mkdir -p ${GOPATH}/src/github.com/tektoncd && cd $_
git clone --branch v0.1.0 https://github.com/tektoncd/triggers.git
cd triggers
#Build required base images
curl -o Dockerfile.build-base-ubi https://raw.githubusercontent.com/ppc64le/build-scripts/master/t/tektoncd-components/base-dockerfiles/Dockerfile.build-base-ubi
docker build -t build/build-base:latest -f Dockerfile.build-base-ubi .

#Changes in .ko.yaml file
echo 'defaultBaseImage: localhost:5000/build/build-base:latest
  # TODO(christiewilson): Use our built base image
  #github.com/tektoncd/triggers/cmd/webhook/: localhost:5000/build/build-base:latest
  #github.com/tektoncd/triggers/cmd/eventlistenersink/: localhost:5000/build/build-base:latest
  #github.com/tektoncd/triggers/cmd/controller: localhost:5000/build/build-base:latest # image should have gsutil in $PATH
' >.ko.yaml

#Create a local registry & push required base images 
docker run -d --name registry -p 5000:5000 ppc64le/registry:2
#Push image
docker tag build/build-base:latest localhost:5000/build/build-base:latest
docker push localhost:5000/build/build-base:latest

#Build & publish tektoncd-pipeline images
export KO_DOCKER_REPO=localhost:5000/ko.local
ko publish --platform=linux/ppc64le ./cmd/webhook/
ko publish --platform=linux/ppc64le ./cmd/controller/
ko publish --platform=linux/ppc64le ./cmd/eventlistenersink/
