#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : milvus-lite
# Version       : v2.4.11
# Source repo   : https://github.com/milvus-io/milvus-lite
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -x
WORKDIR=$(pwd)
PACKAGE_NAME=milvus-lite
PACKAGE_VERSION=v2.4.11
PACKAGE_URL=https://github.com/milvus-io/milvus-lite
PACKAGE_DIR=milvus-lite/python

yum install -y wget openblas-devel git python3-pip rust cargo gcc gcc-c++ libstdc++-static which libaio libuuid-devel ncurses-devel libtool m4 autoconf automake ninja-build zlib-devel libffi-devel openssl-devel scl-utils openblas-devel
pip3 install wheel conan==1.64.1 setuptools==70.0.0

# Install CMake
CMAKE_VERSION=3.30.5
CMAKE_REQUIRED_VERSION=3.30.5

create_cmake_conanfile()
{
    touch /usr/local/cmake/conanfile.py
    cat <<EOT >> /usr/local/cmake/conanfile.py
from conans import ConanFile, tools
class CmakeConan(ConanFile):
  name = "cmake"
  package_type = "application"
  version = "${CMAKE_REQUIRED_VERSION}"
  description = "CMake, the cross-platform, open-source build system."
  homepage = "https://github.com/Kitware/CMake"
  license = "BSD-3-Clause"
  topics = ("build", "installer")
  settings = "os", "arch"
  def package(self):
    self.copy("*")
  def package_info(self):
    self.cpp_info.libs = tools.collect_libs(self)
EOT
}

mkdir -p "${WORKDIR}/workspace"
cd "${WORKDIR}/workspace"

# Build and install cmake 3.30.5
if [ -z "$(ls -A $wdir/cmake-${CMAKE_VERSION})" ]; then
    wget -c https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
    tar -zxvf cmake-${CMAKE_VERSION}.tar.gz
    rm -rf cmake-${CMAKE_VERSION}.tar.gz
    cd cmake-${CMAKE_VERSION}
    ./bootstrap --prefix=/usr/local/cmake --parallel=2 -- -DBUILD_TESTING:BOOL=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_USE_OPENSSL:BOOL=ON
else
    cd cmake-${CMAKE_VERSION}
fi
make install -j$(nproc)
export PATH=/usr/local/cmake/bin:$PATH
cmake --version
cd ..

#Clone the package
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout  ${PACKAGE_VERSION}
git submodule update --init --recursive

#build the package
pushd /usr/local/cmake
create_cmake_conanfile
conan export-pkg . cmake/${CMAKE_REQUIRED_VERSION}@ -s os="Linux" -s arch="ppc64le" -f
conan profile update settings.compiler.libcxx=libstdc++11 default
popd
export VCPKG_FORCE_SYSTEM_BINARIES=1
mkdir -p $HOME/.cargo/bin/

cd python/
pip install -r requirements.txt

# Install the package
if ! python3 setup.py install; then
    echo "------------------$PACKAGE_NAME: Installation failed ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Installation_Failure"
    exit 1
else
    echo "------------------$PACKAGE_NAME: Installation successful ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Installation_Success"
    exit 0
fi

#Skipping the testcase because tests has dependency on jax which has dependency on jaxlib which is complex to port. Due to time limitation we have decided to skip tests for now. We will take this afterwards.
