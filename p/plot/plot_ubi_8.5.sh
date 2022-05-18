#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : plot
# Version       : v0.0.0-20190515093506-e2840ee46a6b (e2840ee46a6b)
# Source repo   : https://github.com/gonum/plot.git
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
# ------------------------------------------------------------------------------

PACKAGE_NAME=plot
PACKAGE_VERSION=${1:-e2840ee46a6b}
PACKAGE_URL=https://github.com/gonum/plot.git

yum install -y wget git

#install GO1.17
cd /opt && wget https://golang.org/dl/go1.17.5.linux-ppc64le.tar.gz
tar -xzf go1.17.5.linux-ppc64le.tar.gz
rm -rf go1.17.5.linux-ppc64le.tar.gz
export GOPATH=`pwd`/gopath
export PATH=`pwd`/go/bin:$GOPATH/bin:$PATH

# Clone the Repo.
git clone $PACKAGE_URL
cd $PACKAGE_NAME && git checkout $PACKAGE_VERSION

go mod tidy

echo "Building $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

if ! go install; then
echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
exit 1
else
echo "------------------$PACKAGE_NAME:install_success-------------------------"
fi

if ! go test ; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi
