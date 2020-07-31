# ----------------------------------------------------------------------------
#
# Package         : knative/serving
# Version         : v0.16.0
# Source repo     : https://github.com/knative/serving.git
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
# Go version 1.14.4
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

#Build knative-serving images
mkdir -p ${GOPATH}/src/knative.dev && cd $_
git clone --branch v0.16.0 https://github.com/knative/serving.git
cd serving
#Change base image to ubi
echo 'defaultBaseImage: registry.access.redhat.com/ubi7/ubi:latest' > .ko.yaml
./hack/release.sh --skip-tests --nopublish --notag-release

#Publish images to local registry
ko publish --platform=linux/ppc64le ./cmd/activator/
ko publish --platform=linux/ppc64le ./cmd/autoscaler/
ko publish --platform=linux/ppc64le ./cmd/autoscaler-hpa/
ko publish --platform=linux/ppc64le ./cmd/controller/
ko publish --platform=linux/ppc64le ./cmd/default-domain/
ko publish --platform=linux/ppc64le ./cmd/queue/
ko publish --platform=linux/ppc64le ./cmd/webhook/
ko publish --platform=linux/ppc64le ./cmd/networking/nscert/

#Build storageversion-migrate image:
cd ${GOPATH}/src/knative.dev/
git clone -b release-0.16 https://github.com/knative/pkg.git
cd pkg
#Change base image to ubi
echo 'defaultBaseImage: registry.access.redhat.com/ubi7/ubi:latest' > .ko.yaml

#Publish images to local registry:
ko publish --platform=linux/ppc64le ./apiextensions/storageversion/cmd/migrate/

#Building Knative net-istio images:
cd ${GOPATH}/src/knative.dev/
git clone -b v0.16.0 https://github.com/knative-sandbox/net-istio.git
cd net-istio
#Change base image to ubi
echo 'defaultBaseImage: registry.access.redhat.com/ubi7/ubi:latest' > .ko.yaml
./hack/release.sh --skip-tests --nopublish --notag-release

#Publish images to local registry
ko publish --platform=linux/ppc64le ./cmd/controller/
ko publish --platform=linux/ppc64le ./cmd/webhook/


