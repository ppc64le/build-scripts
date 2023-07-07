#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : golex
# Version       : v1.0.1
# Source repo   : https://gitlab.com/cznic/golex
# Tested on     : UBI 8.3
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

PACKAGE_NAME=modernc.org/golex
PACKAGE_VERSION=${1:-v1.0.1}
PACKAGE_URL=https://gitlab.com/cznic/golex

yum install -y git golang make

go get $PACKAGE_NAME@$PACKAGE_VERSION

cd ~/go/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION
go mod tidy
go install
go test
