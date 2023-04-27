#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package          : collectd
# Version          : main
# Source repo      : https://github.com/collectd/collectd.git
# Tested on        : UBI 8.5
# Language         : C
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : 
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

PACKAGE_NAME=collectd
PACKAGE_VERSION=main
PACKAGE_URL=https://github.com/collectd/collectd

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)


#Dependencies
yum install -y git autoconf automake libtool wget make perl bzip2 m4 
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/flex-2.6.1-9.el8.ppc64le.rpm
rpm -i flex-2.6.1-9.el8.ppc64le.rpm
#flex --version
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/bison-3.0.4-10.el8.ppc64le.rpm
rpm -i bison-3.0.4-10.el8.ppc64le.rpm
#bison --version

# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
./build.sh
./configure $CONFIGURE_FLAGS
if ! make $MAKEFLAGS ; then
	echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
fi
make $MAKEFLAGS check
cat ./test-suite.log || true
if ! make $MAKEFLAG distcheck DISTCHECK_CONFIGURE_FLAGS="--disable-dependency-tracking --enable-debug" ; then
	echo "------------------$PACKAGE_NAME::Build_success_but_Test_fails-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_success_but_Test_fails"
        exit 2
else
	echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
        exit 0
fi
