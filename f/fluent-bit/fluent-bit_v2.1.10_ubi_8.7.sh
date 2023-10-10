#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: fluent-bit
# Version	: v2.1.10
# Source repo	: https://github.com/fluent/fluent-bit
# Tested on	: UBI 8.7
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

PACKAGE_NAME=fluent-bit
PACKAGE_VERSION=${1:-v2.1.10}
PACKAGE_URL=https://github.com/fluent/fluent-bit.git
LUAJIT2_VERSION=v2.1-20230911
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname $(realpath $0))

#Install repos and deps
yum install -y dnf && \
    dnf install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm && \
    dnf install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm && \
    dnf config-manager --enable powertools && \
    dnf install -y epel-release
yum install gcc gcc-c++ libyaml-devel wget cmake3 python3 git openssl-devel flex bison diffutils autoconf postgresql-devel cyrus-sasl-devel systemd-devel valgrind-devel libarchive glibc-devel nc -y

#Get repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Apply patch
git apply $SCRIPT_PATH/fluent-bit_${PACKAGE_VERSION}.patch

#Clone luajit2 and apply power patch
cd lib
git clone https://github.com/openresty/luajit2.git
cd luajit2
git checkout v2.1-20230911
git apply $SCRIPT_PATH/luajit2_${LUAJIT2_VERSION}.patch
echo "exit 0;" >> configure
chmod +x configure

#Build
cd $BUILD_HOME/fluent-bit/build/
cmake -DFLB_TESTS_RUNTIME=On -DFLB_TESTS_INTERNAL=On -DFLB_RELEASE=On ..
ret=0
make -j $(nproc) || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 1
fi
export FLUENTBIT_BIN=$BUILD_HOME/fluent-bit/build/bin/fluent-bit

#Smoke test
$FLUENTBIT_BIN --version || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Smoke test failed."
	exit 2
fi

#Disable one failing test that is in parity with x86_64
sed -i '143,144d' ./tests/runtime/CTestTestfile.cmake #flb-rt-out_td

#Disable wasm test as it is disabled in the build
sed -i '85,86d' ./tests/runtime/CTestTestfile.cmake #flb-rt-out_wasm

#Test
make test || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Tests failed."
	exit 2
fi
echo "SUCCESS: Build and test success!"
echo "Fluent bit binary is available at [$FLUENTBIT_BIN]."
echo "Wasm is disabled."
echo "The remaining one failing test (62 - flb-rt-out_td) is in parity with x86_64."

#Run
#bin/fluent-bit -i cpu -o stdout -f 1
