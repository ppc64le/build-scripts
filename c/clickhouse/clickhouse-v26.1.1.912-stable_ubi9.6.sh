#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : ClickHouse
# Version        : v26.1.1.912-stable
# Source repo    : https://github.com/ClickHouse/ClickHouse.git
# Tested on      : UBI 9.6
# Language       : Python
# Ci-Check       : true
# Maintainer     : Sumit Dubey <sumit.dubey2@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# ----------------------------------------------------------------------------

#Configuration
PACKAGE_NAME="ClickHouse"
PACKAGE_ORG="ClickHouse"
PACKAGE_VERSION="v26.1.1.912-stable"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname $(realpath $0))

#Install repos and dependencies
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y https://rpmfind.net/linux/centos-stream/9-stream/CRB/ppc64le/os/Packages/nasm-2.15.03-7.el9.ppc64le.rpm
dnf install -y git cmake ccache python3 ninja-build yasm gawk wget gcc gcc-c++ xz gnupg kernel-headers expect python3-jinja2 clang-20.1.8-3.el9.ppc64le llvm-20.1.8-3.el9.ppc64le lld-20.1.8-3.el9.ppc64le hostname perl-FindBin perl-IPC-Cmd perl-File-Compare perl-File-Copy perl-Time-Piece perl-Pod-Html 
export CC=clang
export CXX=clang++

#Install rust
cd $BUILD_HOME
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
rustup toolchain install nightly-2025-07-07
rustup default nightly-2025-07-07
rustup component add rust-src

#Clone
cd $BUILD_HOME
git clone $PACKAGE_URL -b $PACKAGE_VERSION
cd $PACKAGE_NAME
git submodule update --init --recursive --jobs $(nproc)
git apply ${SCRIPT_PATH}/${PACKAGE_NAME,,}-${PACKAGE_VERSION}.patch
cp /usr/include/linux/vm_sockets.h contrib/sysroot/linux-powerpc64le/powerpc64le-linux-gnu/libc/usr/include/linux/

#Build openssl
pushd contrib/openssl
./config
make -j$(nproc)
make install
popd

#Build
mkdir build
cd build
cmake -D CMAKE_BUILD_TYPE=Debug -D ENABLE_TESTS=ON -D ENABLE_OPENSSL_DYNAMIC=ON ..
ninja -j$(nproc)
rm -rf programs/libcrypto.so.3 programs/libssl.so.3
cp /usr/local/lib/libcrypto.so.3 /usr/local/lib/libssl.so.3 programs/

#Unit test
./src/unit_tests_dbms

#Conclude
set +ex
echo "Buid and tests complete!"
echo "Binaries available at [$BUILD_HOME/$PACKAGE_NAME/build/programs/]"


#Functional Test
#export MALLOC_CONF="narenas:$(nproc)"
#./programs/clickhouse-server > /dev/null 2>&1 &
#sleep 5
#ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
#cd ..
#./tests/clickhouse-test

