# -----------------------------------------------------------------------------
#
# Package	: howett.net/plist
# Version	: v0.0.0-20181124034731-591f970eefbb
# Source repo	: https://github.com/DHowett/go-plist
# Tested on	: UBI 8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=howett.net/plist
PACKAGE_VERSION=${1:-v0.0.0-20181124034731-591f970eefbb}

yum install -y git golang

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd ~/go/pkg/mod/$PACKAGE_NAME*
if ! go mod tidy; then
	echo "------------------$PACKAGE_NAME:dependency_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Dependency_Fails"
	exit 1
fi

cd ~/go/pkg/mod/$PACKAGE_NAME*
if ! go test; then
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
