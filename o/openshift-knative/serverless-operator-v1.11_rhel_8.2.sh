#----------------------------------------------------------------------------------------
#
# Package		: openshift-knative/serverless-operator
# Version		: release-1.11
# Source repo		: https://github.com/openshift-knative/serverless-operator
# Tested on		: RHEL 8.2
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
# Go version 1.14.6 or higher must be installed
#
#----------------------------------------------------------------------------------------

#!/bin/bash

# environment variables & setup
echo -e "\nSetting up the environment"
#set -x
mkdir -p $HOME/go
mkdir -p $HOME/go/src
mkdir -p $HOME/go/bin
mkdir -p $HOME/go/pkg
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
#export GOFLAGS="-mod=vendor"
#export GO111MODULE=auto
echo $GOPATH && echo $PATH

# alias
shopt -s expand_aliases
source /root/.bashrc

# install yq
#wget https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_ppc64le
#chmod +x yq_linux_ppc64le
#mv yq_linux_ppc64le /usr/bin/yq

# build docker image for openshift/origin-release
echo -e "\n"
echo -e "Building openshift/origin-release image ..."
mkdir -p $GOPATH/src/github.com/openshift && cd $_ && pwd
git clone https://github.com/openshift/release.git
cd release && pwd
git checkout 0fb4497
cd projects/origin-release/golang-1.14/ && pwd
docker build -t openshift/origin-release:golang-1.14 .

# build docker image for openshift/origin-base
echo -e "\n"
echo -e "Building openshift/origin-base image ..."
mkdir -p $GOPATH/src/github.com/openshift && cd $_ && pwd
git clone https://github.com/openshift/images.git
cd images && pwd
git checkout 515726d
cd base && pwd
sed -i "s,registry.svc.ci.openshift.org/ocp/builder:rhel-8-base-openshift-4.7,registry.access.redhat.com/ubi8/ubi-minimal:latest," ./Dockerfile.rhel
sed -i "s,--setopt=install_weak_deps=False,," ./Dockerfile.rhel
docker build -t openshift/origin-base:latest -f ./Dockerfile.rhel .

# create a local registry to push images to
echo -e "\n"
echo -e "Creating local image registry ..."
docker run -it -d --name registry -p 5000:5000 ppc64le/registry:2
export DOCKER_REPO_OVERRIDE=localhost:5000/openshift
# push the images
echo -e "Pushing images to local registry ..."
docker tag openshift/origin-release:golang-1.14 $DOCKER_REPO_OVERRIDE/origin-release:golang-1.14
docker push $DOCKER_REPO_OVERRIDE/origin-release:golang-1.14
docker tag openshift/origin-base:latest $DOCKER_REPO_OVERRIDE/origin-base:latest
docker push $DOCKER_REPO_OVERRIDE/origin-base:latest

# build serverless-operator images
echo -e "\n"
echo -e "Building serverless operator images ..."
mkdir -p $GOPATH/src/github.com/openshift-knative && cd $_ && pwd
git clone https://github.com/openshift-knative/serverless-operator.git
cd serverless-operator && pwd
git checkout release-1.11
git branch -vv
make images

# execute unit tests
echo -e "\n"
echo -e "Executing unit test ..."
make test-unit

# exit message
echo -e "\n"
echo -e "Script completed ..."
