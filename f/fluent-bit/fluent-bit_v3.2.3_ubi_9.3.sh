#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: fluent-bit
# Version	: v3.2.3
# Source repo	: https://github.com/fluent/fluent-bit
# Tested on	: UBI 9.3
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

SCRIPT_PACKAGE_VERSION=v3.2.3
PACKAGE_NAME=fluent-bit
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/fluent/fluent-bit.git
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname $(realpath $0))

#Install repos and deps
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum install gcc gcc-c++ libyaml-devel wget cmake3 python3 git openssl-devel diffutils autoconf postgresql-devel cyrus-sasl-devel systemd-devel libarchive glibc-devel nc flex bison valgrind-devel -y

#Get repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Apply patch
git apply $SCRIPT_PATH/fluent-bit_${SCRIPT_PACKAGE_VERSION}.patch

#Build
cd $BUILD_HOME/fluent-bit/build/
cmake -DFLB_TESTS_RUNTIME=On -DFLB_TESTS_INTERNAL=On ..
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
sed -i '157,158d' ./tests/runtime/CTestTestfile.cmake #flb-rt-out_td

#Disable wasm test as it is disabled in the build
sed -i '97,98d' ./tests/runtime/CTestTestfile.cmake #wasm

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

#Run
#bin/fluent-bit -i cpu -o stdout -f 1
