# ---------------------------------------------------------------------
# 
# Package       : go-http-tunnel
# Version       : latest tag
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/mmatczuk/go-http-tunnel.git
PACKAGE_VERSION=2.1

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
yum update -y

yum install -y git make golang gcc gcc-c++
#install dependencies

#clone the repo
git clone $REPO
cd go-http-tunnel/
#git checkout $PACKAGE_VERSION
#build and install the repo.
go get -u github.com/mmatczuk/go-http-tunnel/cmd/...
go get -v -u golang.org/x/lint/golint
go get -u github.com/gordonklaus/ineffassign

go build && go install

#test
#Note: few test cases are failing on both vm power and intel.
go test
