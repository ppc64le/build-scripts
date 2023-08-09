#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package		: opendatahub-io/data-science-pipelines-operator
# Version		: v0.2.0
# Source repo	: https://github.com/opendatahub-io/data-science-pipelines-operator.git
# Tested on		: UBI 8.5
# Language		: GO
# Travis-Check	: True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vaishnavi Patil <Vaishnavi.Patil3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=data-science-pipelines-operator
PACKAGE_VERSION=v0.2.0
PACKAGE_URL=https://github.com/opendatahub-io/data-science-pipelines-operator.git

yum install -y git wget make gcc-c++ unzip

# Install Go and setup working directory
rm -rf /bin/go

GO_VERSION=go1.20.4

wget https://go.dev/dl/$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz
rm -f $GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 0
fi

cd $PACKAGE_NAME

echo " --------------------------------- checkout version  $PACKAGE_VERSION ------------------------------------"
git checkout $PACKAGE_VERSION

if ! make build ; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
	exit 1
fi


if ! make test ; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi
