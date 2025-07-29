#!/bin/bash

# ----------------------------------------------------------------------------
# Package       : ginkgo
# Version       : v2.23.4
# Source repo   : https://github.com/onsi/ginkgo
# Tested on     : UBI:9.6
# Language      : Go
# Travis-Check  : True
# Script License: MIT License
# Maintainer    : Pooja Dalai <Pooja.Dalai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

PACKAGE_NAME=ginkgo
PACKAGE_VERSION=${1:-v2.23.4}
PACKAGE_URL=https://github.com/onsi/ginkgo

yum install -y git wget gcc

#Install go
export GO_VERSION=${GO_VERSION:-1.24.1}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin

wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#checks for logic errors and subtle bugs
go vet ./...

#Build and test
if ! go install ./...; then
echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

if ! go run ./ginkgo --github-output -r -randomize-all -randomize-suites -race -trace -procs=2 -poll-progress-after=10s -poll-progress-interval=10s; then
echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi
