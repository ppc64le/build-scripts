# ----------------------------------------------------------------------------
#
# Package         : knative/operator
# Version         : v0.16.0
# Source repo     : https://github.com/knative/operator.git
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Nailusha Potnuru <pnailush@in.ibm.com>
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
# Docker must be installed and running
#
# Go version 1.12.1 or higher must be installed
#
# ----------------------------------------------------------------------------

set -e

yum update -y
yum install git -y

export GOPATH=${HOME}/go
export GOROOT=/usr/local/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export GOFLAGS="-mod=vendor"
export GO111MODULE=auto

#Install go packages
go get -u github.com/golang/dep/cmd/dep
#Offical ko repo doesnot support multiplatform build
#PR: https://github.com/google/ko/pull/38
#Once PR is merged, we can use "go get -u github.com/google/ko/cmd/ko"
mkdir -p ${GOPATH}/src/github.com/google && cd $_
git clone -b multi-platform-wip https://github.com/jonjohnsonjr/ko.git
cd ko/cmd/ko/
go install

#Create a local registry to push images to
docker run -it -d --name registry -p 5000:5000 ppc64le/registry:2
export KO_DOCKER_REPO=localhost:5000/knative

#Build knative operator images
mkdir -p ${GOPATH}/src/knative.dev && cd $_
git clone --branch v0.16.0 https://github.com/knative/operator.git
cd operator
#Change base image to ubi
echo 'defaultBaseImage: registry.access.redhat.com/ubi7/ubi:latest' > .ko.yaml
sed -i 's|ko://knative.dev/operator/cmd/operator|localhost:5000/knative.dev/operator/cmd/operator|g' config/operator.yaml
./hack/release.sh --skip-tests --nopublish --notag-release

#Publish images to local registry
ko publish --platform=linux/ppc64le ./cmd/operator/

