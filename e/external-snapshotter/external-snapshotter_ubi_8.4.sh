# -----------------------------------------------------------------------------
#
# Package	: github.com/kubernetes-csi/external-snapshotter
# Version	: Commit # cd45bdb
# Source repo	: https://github.com/kubernetes-csi/external-snapshotter
# Tested on	: UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_URL=http://github.com/kubernetes-csi/external-snapshotter
PACKAGE_NAME=external-snapshotter
PACKAGE_VERSION=${1:-cd45bdb}

yum install -y git golang

HOME_DIR=`pwd`

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

make

#There are some test failures on that are in parity with x86, these are listed below
#FAIL    github.com/kubernetes-csi/external-snapshotter/v4/pkg/sidecar-controller [build failed]
#FAIL    github.com/kubernetes-csi/external-snapshotter/v4/pkg/snapshotter [build failed]
#FAIL    github.com/kubernetes-csi/external-snapshotter/v4/pkg/utils [build failed]
#FAIL    github.com/kubernetes-csi/external-snapshotter/v4/pkg/validation-webhook [build failed]

if ! go test -v ./...; then
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
