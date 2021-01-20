#----------------------------------------------------------------------------------------
#
# Package			: knative/test-infra
# Version			: release-0.16
# Source repo		: https://github.com/knative/test-infra
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

# clone the repository (commit id #ea4d6e9)
mkdir -p ${GOPATH}/src/knative.dev/ && cd $_
git clone -b release-0.16 https://github.com/knative/test-infra.git
cd test-infra
pwd && ls
# change base image to ubi
echo 'defaultBaseImage: registry.access.redhat.com/ubi7/ubi:latest' > .ko.yaml
# build and install kntest
go install ./kntest/cmd/kntest
which kntest

# execute unit tests
go test -v -count=1 ./... > ./log-unittest.txt 2>&1
#./test/presubmit-tests.sh --unit-tests > ./log-presubmittest.txt 2>&1
