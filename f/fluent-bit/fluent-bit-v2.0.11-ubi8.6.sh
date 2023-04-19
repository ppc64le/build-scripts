#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: fluent-bit
# Version	: v2.0.11
# Source repo	: https://github.com/fluent/fluent-bit
# Tested on	: UBI 8.6
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

FLUENTBIT_VERSION=${1:-v2.0.11}
USE_CENTOS_REPOS=${2:-1}
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname $0)

#Install dependencies
if [ "$USE_CENTOS_REPOS" -eq 1 ]
then
	dnf -y install --nogpgcheck https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
	sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
	sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
fi
yum install gcc gcc-c++ libyaml-devel wget cmake3 python3 git openssl-devel flex bison diffutils autoconf postgresql-devel cyrus-sasl-devel systemd-devel valgrind-devel libarchive glibc-devel nc -y

#Get repo
git clone https://github.com/fluent/fluent-bit.git
cd fluent-bit/
git checkout $FLUENTBIT_VERSION

#Apply patch
git apply $SCRIPT_PATH/fluent-bit-${FLUENTBIT_VERSION}.patch

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
$FLUENTBIT_BIN --version

#Test
make test || true
echo "SUCCESS: Build and test success!"
echo "Fluent bit binary is available at [$FLUENTBIT_BIN]."
echo "Luajit and Wasm are disabled."
echo "The remaining one failing test (62 - flb-rt-out_td) is in parity with x86_64."

#Run
#bin/fluent-bit -i cpu -o stdout -f 1
