#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : geo
# Version       : 5b978397cfec, master
# Source repo   : https://github.com/golang/geo
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prashant Khoje <prashant.khoje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=geo
# Defaults to PACKAGE_VERSION=v0.0.0-20190916061304-5b978397cfec
# This script also works with master branch.
PACKAGE_VERSION=${1:-5b978397cfec}
PACKAGE_URL="https://github.com/golang/geo.git"

export GOPATH=$HOME/go
dnf install -y golang git

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export SRC=$GOPATH/src/github.com/$PACKAGE_NAME
mkdir -p $SRC
cd $SRC
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "\nFollowing tests fail due to floating point precision differences on ppc64le platform:"
echo "\tTestClosestEdgeQueryTrueDistanceLessThanChordAngleDistance"
echo "\tTestPointMeasuresPointArea"
echo "\tTestPredicatesRobustSignEqualities\n"

echo "Testing $PACKAGE_NAME with $PACKAGE_VERSION"
if ! go test -v ./...; then
    echo "------------------ $PACKAGE_NAME: test fail ---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Test fails"
    exit 1
else
    echo "------------------ $PACKAGE_NAME: test success --------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass | Test success"
fi
