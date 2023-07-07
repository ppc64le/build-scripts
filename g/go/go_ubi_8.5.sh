#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ugorji/go
# Version       : v1.1.4
# Source repo   : https://github.com/ugorji/go.git
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/ugorji/go
PACKAGE_VERSION=${1:-v1.1.4}
PACKAGE_URL=https://github.com/ugorji/go.git

yum install -y git golang

go get $PACKAGE_NAME@$PACKAGE_VERSION

cd ~/go/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION/codec
go mod tidy
go install
go test
