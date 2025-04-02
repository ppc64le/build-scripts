#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package          : libuv
# Version          : v1.x
# Source repo      : https://github.com/libuv/libuv.git
# Tested on        : UBI 8.5
# Language         : C
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : valipi_venkatesh@persistent.com
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

PACKAGE_NAME=libuv
PACKAGE_VERSION=v1.x
PACKAGE_URL=https://github.com/libuv/libuv

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)


#install C dependencies
yum install -y git make autoconf libtool automake sudo 

#Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
./autogen.sh
./configure
if ! make ; then
	echo "------------------$PACKAGE_NAME:build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

# Run the test suite as a non-root user
sudo useradd -r libuv-tester
sudo chown -R libuv-tester .
if ! sudo -u libuv-tester make check ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi

 

