#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : go-tools
# Version       : v0.3.0-0.dev, v0.2.1
# Source repo   : https://github.com/dominikh/go-tools
# Tested on     : UBI 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Ghumnar / Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com> / Vaishnavi Patil <Vaishnavi.Patil3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

VERSION=${1:-v0.3.0-0.dev}

if [ -d "go-tools" ] ; then
  rm -rf go-tools
fi

# Dependency installation
dnf install -y git go

mkdir -p /home/tester/go
export GOPATH=/home/tester/go

mkdir -p $GOPATH/src/github.com/dominikh

cd $GOPATH/src/github.com/dominikh
# Download the repos
git clone https://github.com/dominikh/go-tools

# Build and Test go-tools
cd go-tools
git checkout $VERSION
export GO111MODULE="auto"
go test -v ./...
go get honnef.co/go/tools/cmd/staticcheck
go vet ./...
$(go env GOPATH)/bin/staticcheck ./...
