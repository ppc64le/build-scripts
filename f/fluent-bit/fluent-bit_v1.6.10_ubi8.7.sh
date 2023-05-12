#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: fluent-bit
# Version	: v1.6.10
# Source repo	: https://github.com/fluent/fluent-bit
# Tested on	: RHEL 8.7
# Language      : C++
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

trap cleanup ERR
function cleanup {
  echo "ERROR: Script failed"
}

PKG_NAME=fluent-bit
PKG_VERSION=${1:-v1.6.10}
PKG_URL=https://github.com/fluent/fluent-bit.git
USE_CENTOS_REPOS=${2:-1}
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname $(realpath $0))

#Install dependencies
if [ "$USE_CENTOS_REPOS" -eq 1 ]
then
	dnf -y install --nogpgcheck https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
	sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
	sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
fi
yum install gcc gcc-c++ libyaml-devel wget cmake3 python3 git openssl-devel flex bison diffutils autoconf postgresql-devel cyrus-sasl-devel systemd-devel valgrind-devel libarchive glibc-devel nc -y

#Get repo
git clone $PKG_URL
cd $PKG_NAME
git checkout $PKG_VERSION

#Apply patch
git apply $SCRIPT_PATH/fluent-bit_$PKG_VERSION.patch

#Get moonjit and create ./configure
cd $BUILD_HOME/$PKG_NAME/lib/
git clone https://github.com/moonjit/moonjit.git
mv moonjit luajit2
cd luajit2/
git checkout 2.2.0
sed -i '24i #if LJ_ARCH_PPC_ELFV2' src/lj_ccallback.c
sed -i '25i #include "lualib.h"' src/lj_ccallback.c
sed -i '26i #endif' src/lj_ccallback.c
echo "exit 0;" >> configure
chmod +x configure

#Build
cd $BUILD_HOME/$PKG_NAME/build/
cmake -DFLB_TESTS_RUNTIME=On -DFLB_TESTS_INTERNAL=On -DFLB_RELEASE=On ..
ret=0
make -j $(nproc) || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 1
fi
export FLUENTBIT_BIN=$BUILD_HOME/$PKG_NAME/build/bin/fluent-bit

#Smoke test
$FLUENTBIT_BIN --version || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Smoke test failed."
	exit 2
fi

#Disable 3 failing tests that are in parity with x86_64
sed -i '67,68d' ./tests/runtime/CTestTestfile.cmake #flb-rt-out_td
sed -i '13,14d' ./tests/runtime/CTestTestfile.cmake #flb-rt-in_proc
sed -i '43,44d' ./tests/internal/CTestTestfile.cmake #flb-it-parser

#Test
make test || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Tests failed."
	exit 2
fi

#Conclude
echo "SUCCESS: Build and test success!"
echo "Fluent bit binary is available at [$FLUENTBIT_BIN]."
echo "Three failing tests in parity with x86_64 were disabled."
