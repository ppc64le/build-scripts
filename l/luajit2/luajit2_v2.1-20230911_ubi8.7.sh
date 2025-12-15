#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : luajit2
# Version       : v2.1-20230911
# Source repo   : https://github.com/openresty/luajit2
# Tested on     : UBI 8.7
# Language      : C
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=luajit2
PACKAGE_VERSION=${1:-v2.1-20230911}
PACKAGE_URL=https://github.com/openresty/${PACKAGE_NAME}.git
TEST_SUITE_VERSION=1fa1f10
wdir=`pwd`
SCRIPT_PATH=$(dirname $(realpath $0))

#Install repos
yum install -y dnf && \
    dnf install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm && \
    dnf install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm && \
    dnf config-manager --enable powertools && \
    dnf install -y epel-release

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
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
git apply $SCRIPT_PATH/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch

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

#Test
cd $wdir
git clone https://github.com/openresty/luajit2-test-suite.git
cd luajit2-test-suite
git checkout ${TEST_SUITE_VERSION}
git apply $SCRIPT_PATH/luajit2-test-suite_${TEST_SUITE_VERSION}.patch
./run-tests -v  /usr/local || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "Tests fail."
	exit 2
fi

#Conclude
set +ex
echo "Build and tests Successful!"

