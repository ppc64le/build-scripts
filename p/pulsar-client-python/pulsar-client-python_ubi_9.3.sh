#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pulsar-client-python
# Version       : v3.5.0
# Source repo   : https://github.com/apache/pulsar-client-python.git
# Tested on     : UBI 9.3
# Language      : Python
# Ci-Check  : True
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
 
PACKAGE_NAME=pulsar-client-python
PACKAGE_VERSION=${1:-v3.5.0}
PACKAGE_URL=https://github.com/apache/pulsar-client-python.git
PACKAGE_DIR=pulsar-client-python
CURRENT_DIR="${PWD}"
 
# Install dependencies
yum install -y git python-devel gcc gcc-c++ gzip tar make wget xz cmake yum-utils \
    openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel \
    autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le \
    fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel perl perl-devel \
    perl-CPAN llvm llvm-devel clang-tools-extra ninja-build
 
echo "Building protobuf"
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
echo "Compiling the source code..."
make -j$(nproc)
echo "Installing protobuf..."
make install
 
cd $CURRENT_DIR
 
echo "Building pulsar-client-python repository"
# Clone the pulsar-client-python repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}
 
echo "Building pulsar-client-cpp"
# Build pulsar-client-cpp
git clone https://github.com/apache/pulsar-client-cpp.git
cd pulsar-client-cpp
git submodule update --init --recursive
 
# Build Vcpkg
cd vcpkg
export VCPKG_FORCE_SYSTEM_BINARIES=1
./bootstrap-vcpkg.sh
cd ..
echo "Compiling the source code..."
cmake -B build -DINTEGRATE_VCPKG=ON
echo "Compiling the source code..."
cmake --build build -j8
echo "Compiling the source code..."
cmake -B build -DINTEGRATE_VCPKG=ON -DCMAKE_INSTALL_PREFIX=/tmp/pulsar
echo "Installing pulsar-client-cpp"
cmake --build build -j8 --target install
cd ..
 
echo "Installing necessary dependencies"
# Python dependencies
pip3 install pyyaml wheel
 
echo "Building pybind11"
# Build pybind11
git clone https://github.com/pybind/pybind11.git
cd pybind11
mkdir build && cd build
cmake ..
echo "Compiling the source code..."
make
echo "Installing pybind11"
make install
cd ../..
 
# Final build step for Python binding
cmake -B build \
    -DPULSAR_LIBRARY=$CURRENT_DIR/pulsar-client-python/pulsar-client-cpp/build/lib/libpulsar.so \
    -DPULSAR_INCLUDE=$CURRENT_DIR/pulsar-client-python/pulsar-client-cpp/include \
    -DPYBIND11_INCLUDE_DIR=$CURRENT_DIR/usr/local/include/pybind11
echo "Compiling the source code..."
cmake --build build
 
echo "Installing..."
# Install the package
if ! (cmake --install build); then
    echo "------------------ $PACKAGE_NAME: Installation failed ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Installation_Failure"
    exit 1
else
    echo "------------------ $PACKAGE_NAME: Installation successful ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Installation_Success"
    exit 0
fi
