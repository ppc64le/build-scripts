#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pulsar-client-python
# Version       : v3.5.0
# Source repo   : https://github.com/apache/pulsar-client-python.git
# Tested on     : UBI 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such cases, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -x

# Install dependencies
yum install -y git python-devel gcc gcc-c++ gzip tar make wget xz cmake yum-utils \
    openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel \
    autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le \
    fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel perl perl-devel \
    perl-CPAN llvm llvm-devel clang-tools-extra ninja-build

PACKAGE_NAME=pulsar-client-python
PACKAGE_VERSION=${1:-3.5.0}
PACKAGE_URL=https://github.com/apache/pulsar-client-python.git
PACKAGE_DIR=pulsar-client-python

# Build protobuf
git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
git checkout v3.20.2
git submodule update --init --recursive
mkdir build_source && cd build_source
cmake ../cmake -Dprotobuf_BUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_SYSCONFDIR=/etc \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -Dprotobuf_BUILD_TESTS=OFF \
    -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
make install
cd ../..

# Clone the pulsar-client-python repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout v${PACKAGE_VERSION}

# Build pulsar-client-cpp
git clone https://github.com/apache/pulsar-client-cpp.git
cd pulsar-client-cpp
git submodule update --init --recursive

# Build Vcpkg
cd vcpkg
export VCPKG_FORCE_SYSTEM_BINARIES=1
./bootstrap-vcpkg.sh
cd ..

cmake -B build -DINTEGRATE_VCPKG=ON
cmake --build build -j8
cmake -B build -DINTEGRATE_VCPKG=ON -DCMAKE_INSTALL_PREFIX=/tmp/pulsar
cmake --build build -j8 --target install
cd ..

# Python dependencies
pip3 install pyyaml wheel

# Build pybind11
git clone https://github.com/pybind/pybind11.git
cd pybind11
mkdir build && cd build
cmake ..
make
make install
cd ../..

# Final build step for Python binding
cmake -B build \
    -DPULSAR_LIBRARY=/pulsar-client-python/pulsar-client-cpp/build/lib/libpulsar.so \
    -DPULSAR_INCLUDE=/pulsar-client-python/pulsar-client-cpp/include \
    -DPYBIND11_INCLUDE_DIR=/usr/local/include/pybind11
cmake --build build

# Install the package
if ! (
    cmake -B build \
        -DPULSAR_LIBRARY=/pulsar-client-python/pulsar-client-cpp/build/lib/libpulsar.so \
        -DPULSAR_INCLUDE=/pulsar-client-python/pulsar-client-cpp/include \
        -DPYBIND11_INCLUDE_DIR=/usr/local/include/pybind11
    cmake --build build
    cmake --install build
); then
    echo "------------------ $PACKAGE_NAME: Installation failed ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Installation_Failure"
    exit 1
else
    echo "------------------ $PACKAGE_NAME: Installation successful ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Installation_Success"
    exit 0
fi

#Skipping the testcase because for we have to must ensure that Pulsar service is running which is taking time .Due to time limitation we have decided to skip tests for now. We will take this afterwards.
