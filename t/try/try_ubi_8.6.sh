#!/bin/bash -ex

# -----------------------------------------------------------------------------
#
# Package       : try
# Version       : 9ac251b645a2,master
# Source repo   : https://github.com/matryer/try
# Tested on     : UBI 8.6
# Language      : GO 
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer : Siddesh Sangodkar <siddesh226@gmail.com>
#
# Disclaimer: This script has been tested in root mode on given 
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=try
# Defaults to PACKAGE_VERSION=9ac251b645a2
# This script also works with master branch.
PACKAGE_VERSION=${1:-9ac251b645a2}
PACKAGE_URL="https://github.com/matryer/try.git"

dnf install -y git golang 

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# set GOPATH
export GOPATH=$HOME/go

# Install try 
mkdir -p $GOPATH/src/github.com/matryer
cd $GOPATH/src/github.com/matryer
git clone $PACKAGE_URL
cd try
git checkout $PACKAGE_VERSION

#Add testcase patch
sed -i "12i var value string"  try_test.go
sed -i "19s/^/\\/\\//" try_test.go
sed -i "34s/^/\\/\\//" try_test.go

if ! go mod init ; then
        echo "------------------$PACKAGE_NAME:initialize_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Initialize_Fails"
        exit 1
fi

if ! go mod tidy ; then
        echo "------------------$PACKAGE_NAME:initialize_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Initialize_Fails"
        exit 1
fi


if ! go test -v  ./... ; then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_and_Test_Success"
        exit 0
fi

echo "Complete!"
