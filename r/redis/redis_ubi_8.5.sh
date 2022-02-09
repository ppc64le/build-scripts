#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: redis
# Version	: 5.0.9
# Source repo	: https://github.com/redis/redis
# Tested on	: UBI 8.5
# Language      : C
# Travis-Check  : True
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

PACKAGE_NAME=redis
PACKAGE_VERSION=${1:-5.0.9}
PACKAGE_URL=https://github.com/redis/redis

yum install -y git gcc diffutils tcl procps make

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
HOME_DIR=`pwd`

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    	exit 0
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
# Clean any previously build dependencies and files, useful for reinstall/upgrade
if ! make distclean; then
     	echo "------------------$PACKAGE_NAME:cleanup_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Cleanup_Fails"
	exit 1
fi

if ! make; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

# Skip 2 tests for ppc64le, reference: https://github.com/redis/redis/issues/8265#issuecomment-756764695
echo "Active defrag" > skipfile
echo "Active defrag big keys" >> skipfile

cd $HOME_DIR/$PACKAGE_NAME
if ! ./runtest --skipfile skipfile; then
	echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails"
	exit 1

fi

cd $HOME_DIR/$PACKAGE_NAME
# Install built & tested binaries
if ! make install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_test_&_install_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Build_Test_and_Install_Success"
	exit 0
fi
