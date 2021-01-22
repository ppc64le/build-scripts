# ----------------------------------------------------------------------------
#
# Package         : knative/eventing-contrib
# Version         : v0.16.0
# Source repo     : https://github.com/knative/eventing-contrib.git
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
# Go version 1.13.5 or higher must be installed
#
# ----------------------------------------------------------------------------

set -e

yum update -y
yum install git -y

export GOPATH=${HOME}/go
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

#Build knative-eventing-contrib images
mkdir -p ${GOPATH}/src/github.com/knative && cd $_
git clone --branch v0.16.0 https://github.com/knative/eventing-contrib.git
cd eventing-contrib
#Change base image to ubi
echo 'defaultBaseImage: registry.access.redhat.com/ubi7/ubi:latest' > .ko.yaml
./hack/release.sh --skip-tests --nopublish --notag-release

#Publish images to local registry
ko publish --platform=linux/ppc64le ./cmd/appender/
ko publish --platform=linux/ppc64le ./cmd/event_display/
ko publish --platform=linux/ppc64le ./cmd/heartbeats/
ko publish --platform=linux/ppc64le ./cmd/heartbeats_receiver/
ko publish --platform=linux/ppc64le ./cmd/websocketsource/
ko publish --platform=linux/ppc64le ./awssqs/cmd/receive_adapter/
ko publish --platform=linux/ppc64le ./awssqs/cmd/controller/
ko publish --platform=linux/ppc64le ./camel/source/cmd/controller/
ko publish --platform=linux/ppc64le ./ceph/cmd/receive_adapter
ko publish --platform=linux/ppc64le ./couchdb/source/cmd/receive_adapter
ko publish --platform=linux/ppc64le ./couchdb/source/cmd/controller/
ko publish --platform=linux/ppc64le ./couchdb/source/cmd/webhook/
ko publish --platform=linux/ppc64le ./github/cmd/receive_adapter/
ko publish --platform=linux/ppc64le ./github/cmd/controller/
ko publish --platform=linux/ppc64le ./github/cmd/mt_receive_adapter/
ko publish --platform=linux/ppc64le ./github/cmd/webhook/
ko publish --platform=linux/ppc64le ./gitlab/cmd/receive_adapter/
ko publish --platform=linux/ppc64le ./gitlab/cmd/controller/
ko publish --platform=linux/ppc64le ./gitlab/cmd/webhook/
ko publish --platform=linux/ppc64le ./kafka/source/cmd/receive_adapter
ko publish --platform=linux/ppc64le ./kafka/source/cmd/controller/
ko publish --platform=linux/ppc64le ./kafka/channel/cmd/webhook/
ko publish --platform=linux/ppc64le ./kafka/channel/cmd/channel_controller/
ko publish --platform=linux/ppc64le ./kafka/channel/cmd/channel_dispatcher/
ko publish --platform=linux/ppc64le ./natss/cmd/channel_controller/
ko publish --platform=linux/ppc64le ./natss/cmd/channel_dispatcher/
ko publish --platform=linux/ppc64le ./prometheus/cmd/receive_adapter/
ko publish --platform=linux/ppc64le ./prometheus/cmd/controller/
ko publish --platform=linux/ppc64le ./prometheus/cmd/webhook/

