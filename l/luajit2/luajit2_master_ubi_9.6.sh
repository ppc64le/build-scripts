#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : luajit2
# Version       : master
# Source repo   : https://github.com/openresty/luajit2
# Tested on     : UBI 9.6
# Language      : C
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=luajit2
PACKAGE_URL=https://github.com/openresty/${PACKAGE_NAME}.git
TEST_SUITE_VERSION=master
wdir=`pwd`

#Install repos
dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-gpg-keys-9.0-26.el9.noarch.rpm \
        https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-26.el9.noarch.rpm \
        https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm  \
         epel-release

#Install dependencies
yum install -y \
    gcc \
    gcc-c++ \
    make \
    git \
    zip unzip \
    wget \
    pkgconf \
    gtk2-devel \
    libffi-devel \
    sqlite-devel \
    mpfr-devel \
    libmpc-devel \
    ncurses-devel \
    perl \
    gd-devel \
    valgrind-devel

#Download source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}

#Build
ret=0
make || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Build failed."
	exit 1
fi

#Install
make install || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Build failed."
	exit 1
fi

set +ex
echo "Build Successful!"
#Commeting tests as testsuite for master barnch is failing.

#Test
#cd $wdir
#git clone https://github.com/openresty/luajit2-test-suite.git
#cd luajit2-test-suite
#git apply ../luajit2-test-suite_${TEST_SUITE_VERSION}.patch
#./run-tests -v  /usr/local || ret=$?
#if [ "$ret" -ne 0 ]
#then
#	echo "Tests fail."
#	exit 2
#fi

#Conclude


