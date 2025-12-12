#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pulsar-client-cpp
# Version       : 3.7.0
# Source repo   : https://github.com/apache/pulsar-client-cpp.git
# Tested on     : UBI:9.6
# Ci-Check      : True
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=pulsar-client-cpp
PACKAGE_VERSION=${1:-v3.7.0}
PACKAGE_URL=https://github.com/apache/pulsar-client-cpp.git
PACKAGE_DIR=pulsar-client-cpp

yum install -y git python3.12-devel python3.12-pip gcc-toolset-13 gzip tar make wget xz cmake yum-utils \
    openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel \
    autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le \
    fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel perl perl-devel \
    perl-CPAN llvm llvm-devel clang-tools-extra ninja-build

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}
git submodule update --init --recursive

# Output directory for compiled C++ libs
INSTALL_DIR=$(pwd)/local/pulsar_client_cpp
mkdir -p ${INSTALL_DIR}

# Build vcpkg
cd vcpkg
export VCPKG_FORCE_SYSTEM_BINARIES=1
./bootstrap-vcpkg.sh
cd ..

# Configure build
cmake -B build \
    -DINTEGRATE_VCPKG=ON \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}

# Build and install
cmake --build build -j$(nproc)
cmake --build build -j$(nproc) --target install


# Fetch pyproject.toml
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pulsar-client-cpp/pyproject.toml
sed -i s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g pyproject.toml

# Install Python package
if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "Build and installation completed successfully."
echo "There are no .py test cases files available. Skipping the test cases."
