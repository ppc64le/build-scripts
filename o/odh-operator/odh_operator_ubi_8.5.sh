#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	     : opendatahub-io/opendatahub-operator
# Version	     : v1.7.0
# Source repo    : https://github.com/opendatahub-io/opendatahub-operator
# Tested on	     : UBI 8.5
# Language       : GO
# Travis-Check   : TRUE
# Script License : Apache License, Version 2 or later
# Maintainer	 : Sonal Mahambrey <Sonal.Mahambrey1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=opendatahub-operator
PACKAGE_URL=https://github.com/opendatahub-io/opendatahub-operator
PACKAGE_VERSION=${1:-v1.7.0}

GO_VERSION=go1.18.4

yum install -y git wget make


# install go
rm -rf /bin/go
wget https://go.dev/dl/$GO_VERSION.linux-ppc64le.tar.gz 
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz  
rm -f $GO_VERSION.linux-ppc64le.tar.gz
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go
export CGO_ENABLED=0


# install ODH-Operator package
cd /
if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
     echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 1
fi

cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION" || exit 1

if ! make build; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
	exit 1
fi

#Tests needs to be run on cluster


