# ----------------------------------------------------------------------------
#
# Package        : mint
# Version        : 
# Source repo    : https://github.com/bifurcation/mint
# Tested on      : UBI 8.4
# Script License : Apache License, Version 2 or later
# Maintainer     : Sapana Khemkar <spana.khemkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

set -eu

#PACKAGE_VERSION="${1:-v8.1.5}"
GO_VERSION=1.17.3

cd /
yum install -y wget git tar && \
wget https://golang.org/dl/go1.17.3.linux-ppc64le.tar.gz && \
tar -C /bin -xzf go1.17.3.linux-ppc64le.tar.gz && \

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
go get -d -t  github.com/bifurcation/mint && \
cd /home/tester/go/pkg/mod/github.com/bifurcation/mint@v0.0.0-20210616192047-fd18df995463

go mod init &&
#fetch all the dependencies for testing
go mod tidy
#run test
go test -v ./... 
#go run build.go build
#go test -v ./pkg/...
exit 0

