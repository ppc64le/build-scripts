#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : backoff
# Version       : v3.0.0, v4.1.1
# Source repo   : https://github.com/cenkalti/backoff.git
# Tested on     : ubi8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Vikas . <kumar.vikas@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=backoff
PACKAGE_VERSION=${1:-v4.1.1}
PACKAGE_URL=https://github.com/cenkalti/backoff

yum install -y wget git tar gcc make

GO_VERSION=1.13

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on
cd /home/tester/go/src

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
 
fi

if ! git clone --recurse $PACKAGE_URL; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    	exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! go build -a -v ./...; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
fi

if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME:test_fails-------------------------------------"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Success_Test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_and_Test_Success"
        echo "------------------$PACKAGE_NAME:Installed at path: /home/tester/go/src/$PACKAGE_NAME------------------------"
        exit 0
fi
