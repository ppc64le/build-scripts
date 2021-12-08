# ----------------------------------------------------------------------------
#
# Package         : knative/operator
# Version         : v0.19.4
# Source repo     : https://github.com/knative/operator.git
# Tested on       : Ubuntu_18.04
# Script License  : Apache License, Version 2.0
# Maintainer      : Vijay Kumar H P <vijaykh1@in.ibm.com>
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
# Go version 1.14.4
# Kubernetes cluster with access to the internet, since the Knative operator downloads images online
# ----------------------------------------------------------------------------

set -e

apt-get install git -y

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
#Export KO_DOCKER_REPO pointing to your docker registry
host=$(kubectl get nodes -lkubernetes.io/hostname!=kind-control-plane -ojsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
export KO_DOCKER_REPO=$host:5000/knative

#Install knative-serving which is required for E2E testing of Kn/operator

#Install CRD's for Knative/Serving
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.19.0/serving-crds.yaml
#Install core components of Serving
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.19.0/serving-core.yaml

#Clone Knative Operator repo
mkdir -p ${GOPATH}/src/knative.dev && cd $_
git clone --branch v0.19.4 https://github.com/knative/operator.git
cd operator

#Remove ingress dependency 
rm -rf cmd/operator/kodata/knative-serving/0.19.0/4-net-istio.yaml

#Install Knative Operator 
ko apply --platform=linux/ppc64le -f config/

#To run all unit tests
go test -v ./...

#end to end tests 
kubectl create namespace knative-operator-testing
go test -v -tags=e2e -count=1 ./test/e2e