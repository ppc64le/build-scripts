#----------------------------------------------------------------------------------------
#
# Package			: knative/pkg
# Version			: v0.16.0
# Source repo		: https://github.com/knative-sandbox/net-istio
# Tested on			: RHEL 7.6
# Script License	: Apache License Version 2.0
# Maintainer		: Pratham Murkute <prathamm@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# 			  Prerequisites: "Go" v1.13.5 or higher and Git must be installed
#
#----------------------------------------------------------------------------------------

#!/bin/bash

# shell environment
set -x

# environment variables & setup
mkdir -p $HOME/go
mkdir -p $HOME/go/src
mkdir -p $HOME/go/bin
mkdir -p $HOME/go/pkg
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export GOFLAGS="-mod=vendor"
export GO111MODULE=auto

# install go packages
go get -u github.com/golang/dep/cmd/dep
# offical ko repo doesnot support multiplatform build
# PR: https://github.com/google/ko/pull/38
# once PR is merged, we can use "go get -u github.com/google/ko/cmd/ko"
mkdir -p ${GOPATH}/src/github.com/google && cd $_
git clone -b multi-platform-wip https://github.com/jonjohnsonjr/ko.git
cd ko/cmd/ko/
go install

# create a local registry to push images to
docker run -it -d --name registry -p 5000:5000 ppc64le/registry:2
export KO_DOCKER_REPO=localhost:5000/knative

# clone the repository
mkdir -p ${GOPATH}/src/knative.dev/ && cd $_
git clone https://github.com/knative-sandbox/net-istio.git
cd net-istio
git checkout -b v0.16.0 tags/v0.16.0
pwd
# change base image to ubi
echo 'defaultBaseImage: registry.access.redhat.com/ubi7/ubi:latest' > .ko.yaml
#./hack/release.sh --skip-tests --nopublish --notag-release

# build and publish images to local registry for controller
ko publish --platform=linux/ppc64le ./cmd/controller/ > ./log-build.txt 2>&1
IMAGE=$(cat ./log-build.txt | tail -1 | awk -F @ '{print $1}')
echo "Image is : $IMAGE"
docker pull $IMAGE
docker inspect $IMAGE | grep Arch

# build and publish images to local registry for webhook
ko publish --platform=linux/ppc64le ./cmd/webhook/ >> ./log-build.txt 2>&1
IMAGE=$(cat ./log-build.txt | tail -1 | awk -F @ '{print $1}')
echo "Image is : $IMAGE"
docker pull $IMAGE
docker inspect $IMAGE | grep Arch

# execute unit tests
go test -v -count=1 ./... > ./log-unittest.txt 2>&1
#./test/presubmit-tests.sh --unit-tests > ./log-presubmittest.txt 2>&1
