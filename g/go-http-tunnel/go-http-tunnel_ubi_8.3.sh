# ---------------------------------------------------------------------
#
# Package       : go-http-tunnel
# Version       : 2.1
# Tested on     : UBI 8.3
# Language      : GO
# Travis-Check  : True
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

set -e

PACKAGE_NAME=go-http-tunnel
PACKAGE_VERSION=${1:-2.1}
PACKAGE_URL=https://github.com/mmatczuk/go-http-tunnel.git

yum install -y git golang
export GOPATH=$(go env GOPATH)

#clone the repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#install dependencies
go mod init $PACKAGE_NAME
go mod tidy
go mod vendor

#Build and test the package.
go install
go test -v ./...
