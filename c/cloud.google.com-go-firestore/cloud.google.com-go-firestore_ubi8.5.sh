#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: cloud.google.com/go/firestore
# Version	: v1.1.0
# Source repo	: https://github.com/googleapis/google-cloud-go/tree/firestore/v1.1.0
# Tested on	: UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Anup Kodlekere <Anup.Kodlekere@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=google-cloud-go/firestore
PACKAGE_VERSION=${1:-firestore/v1.1.0}
PACKAGE_URL=https://github.com/googleapis/google-cloud-go

yum install -y git golang make gcc diffutils patch

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

mkdir -p /home/output

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# edit source code
patch -u --ignore-whitespace from_value.go -i ../../firestore.patch

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/output/version_tracker
	exit 1
fi

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/output/test_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/output/version_tracker
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/output/test_success
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/output/version_tracker
    exit 0
fi