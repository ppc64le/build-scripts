#----------------------------------------------------------------------------------------
#
# Package			: openshift-knative/serverless-operator
# Version			: v1.7.1
# Source repo		: https://github.com/openshift-knative/serverless-operator
# Tested on			: RHEL 7.6
# Script License	: Apache License Version 2.0
# Maintainer		: Pratham Murkute <prathamm@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# Prerequisites: 
# https://github.com/openshift-knative/serverless-operator/tree/release-1.7#requirements
# Docker version 17.05 or higher must be installed
# Go version 1.12.1 or higher must be installed
#
#----------------------------------------------------------------------------------------

#!/bin/bash

# environment variables & setup
mkdir -p $HOME/go
mkdir -p $HOME/go/src
mkdir -p $HOME/go/bin
mkdir -p $HOME/go/pkg
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
#export GOROOT=/usr/local/go
#export PATH=$PATH:$GOROOT/bin
#export GOFLAGS="-mod=vendor"
#export GO111MODULE=auto
echo $GOPATH && echo $PATH

# build docker image for openshift/origin-release
mkdir -p $GOPATH/src/github.com/openshift && cd $_ && pwd
git clone https://github.com/openshift/release.git
cd release && pwd
git checkout fa8e7dc
cd projects/origin-release/golang-1.13/ && pwd
docker build -t openshift/origin-release:golang-1.13 .

# build docker image for openshift/origin-base 
mkdir -p $GOPATH/src/github.com/openshift && cd $_ && pwd
git clone https://github.com/openshift/images.git
cd images && pwd
git checkout 98fd27e
cd base && pwd
docker build -t openshift/origin-base:latest -f ./Dockerfile.rhel .

# create a local registry to push images to
docker run -it -d --name registry -p 5000:5000 ppc64le/registry:2
export DOCKER_REPO_OVERRIDE=localhost:5000/openshift
# push the images
docker tag openshift/origin-release:golang-1.13 $DOCKER_REPO_OVERRIDE/origin-release:golang-1.13
docker push $DOCKER_REPO_OVERRIDE/origin-release:golang-1.13
docker tag openshift/origin-base:latest $DOCKER_REPO_OVERRIDE/origin-base:latest
docker push $DOCKER_REPO_OVERRIDE/origin-base:latest

# build serverless-operator images
mkdir -p $GOPATH/src/github.com/openshift-knative && cd $_ && pwd
git clone https://github.com/openshift-knative/serverless-operator.git
cd serverless-operator && pwd
git checkout -b v1.7.1 fd37d17 # no separate tag for v1.7.1
git branch -vv
make images
