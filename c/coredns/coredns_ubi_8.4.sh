# -----------------------------------------------------------------------------
#
# Package	: github.com/coredns/coredns
# Version	: v1.8.6
# Source repo	: https://github.com/coredns/coredns
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

PACKAGE_URL=http://github.com/coredns/coredns
PACKAGE_NAME=coredns
PACKAGE_VERSION=${1:-v1.8.6}

yum install -y git golang

HOME_DIR=`pwd`

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

git clone $PACKAGE_URL -b $PACKAGE_VERSION
cd $PACKAGE_NAME

make

#Note that there is a test failure which is in parity with Intel
#FAIL    github.com/coredns/coredns/test [build failed]

if ! go test ./...; then
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
