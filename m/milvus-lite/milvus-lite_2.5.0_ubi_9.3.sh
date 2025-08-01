#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : milvus-lite
# Version       : 2.5.0
# Source repo   : https://github.com/milvus-io/milvus-lite
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Vikram Kuppala <sai.vikram.kuppala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
SCRIPT_PATH=$(dirname $(realpath $0))
SCRIPT_PACKAGE_VERSION=v2.5.0
PACKAGE_NAME=milvus-lite
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL="https://github.com/milvus-io/milvus-lite"
PWDIR=$(pwd)

###############################################################################
# 0. System prerequisites
###############################################################################
yum remove -y gcc-toolset-13 || true                # avoid profile conflicts

yum install -y \
        wget perl git cargo gcc gcc-c++ libstdc++-static \
        libaio libuuid-devel ncurses-devel libtool m4 autoconf automake \
        ninja-build zlib-devel libffi-devel scl-utils \
        openblas-devel ncurses-devel xz openssl-devel patch \
        python3.12 python3.12-devel python3.12-pip

# Ensure python3 and pip3 refer to python3.12 explicitly
ln -sf /usr/bin/python3.12 /usr/bin/python3
ln -sf /usr/bin/pip3.12    /usr/bin/pip3

###############################################################################
# 1. Python build tools & Conan
###############################################################################
python3 -m pip install  --upgrade \
        pip \
        wheel \
        "setuptools>=70.0.0" \
        "conan==1.64.1"

###############################################################################
# 2. Build & install Texinfo
###############################################################################
    TEX_VER=7.1
    wget "https://ftp.gnu.org/gnu/texinfo/texinfo-${TEX_VER}.tar.xz"
    tar -xf "texinfo-${TEX_VER}.tar.xz"
    pushd "texinfo-${TEX_VER}"
        ./configure
        make -j2
        make install
    popd
    rm -rf "texinfo-${TEX_VER}"*

###############################################################################
# 3. Install Rust (for Arrow / Parquet deps used in Milvus-Lite)
###############################################################################
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
   | sh -s -- --default-toolchain stable -y
source "$HOME/.cargo/env"
rustc --version

###############################################################################
# 4. Build & register CMake 3.30.5 as a Conan application package
###############################################################################
CMAKE_VERSION=3.30.5
mkdir -p "${PWDIR}/workspace"
pushd "${PWDIR}/workspace"
    if [[ ! -d "cmake-${CMAKE_VERSION}" ]]; then
        wget -c "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz"
        tar -xzf "cmake-${CMAKE_VERSION}.tar.gz"
    fi
    rm -rf cmake-${CMAKE_VERSION}.tar.gz
    cd "cmake-${CMAKE_VERSION}"
    ./bootstrap --prefix=/usr/local/cmake --parallel=2 \
                -- -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_USE_OPENSSL=ON
    make -j2
    make install
popd
export PATH=/usr/local/cmake/bin:$PATH
cmake --version

# Package CMake into Conan so downstream C++ components can depend on a fixed version
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
git clone "${PACKAGE_URL}"
echo "<<<<<<<<<<<<<<<< clonning package directory >>>>>>>"
pushd ${PACKAGE_NAME}
    git checkout "${PACKAGE_VERSION}"
    git submodule update --init --recursive
   PATCH_FILE=${SCRIPT_PATH}/${PACKAGE_NAME}-${SCRIPT_PACKAGE_VERSION}.patch
   #mv "$PATCH_FILE" /milvus-lite/thirdparty/
   #cd thirdparty
   #git apply -p1 $PATCH_FILE
    #PATCH_FILE="/milvus-lite-v2.5.0.patch"
    if [[ -f "${PATCH_FILE}" ]]; then
       echo "patch file path is $PATCH_FILE"
       #patch -p1 --forward < "${PATCH_FILE}"
       patch -d thirdparty/milvus -p1 --forward < "$PATCH_FILE"
       echo "<<<<<<<<<<<<<<<< patch applied properly >>>>>>>"
    else
       echo "Error: Patch file '${PATCH_FILE}' not found!"
    fi
    #git clone https://github.com/conan-io/conan-center-index.git
    #cd conan-center-index/recipes/opentelemetry-proto/all
    #conan export . opentelemetry-proto/1.3.2@
    #cd ../../opentelemetry-cpp/all
    #conan create . opentelemetry-cpp/1.14.2@ --build=missing
popd
export VCPKG_FORCE_SYSTEM_BINARIES=1
pushd /usr/local/cmake
    create_cmake_conanfile
    conan export-pkg . cmake/3.30.5@ -s os=Linux -s arch=$(uname -m) -f
popd
conan profile update settings.compiler.libcxx=libstdc++11 default

###############################################################################
# 5. Clone & build Milvus-Lite Python package
###############################################################################
cd /milvus-lite
# Build Python wheels for py 3.12
pushd python
   echo "<<<<<<<<<<<<<<<< Entering python directory >>>>>>>"
    python3 -m pip install  -r requirements.txt
    python3 -m pip install  build
    python3 setup.py install
    python3 -m build --wheel --no-isolation --outdir "${PWDIR}/"
popd
echo "==========  Milvus-Lite v${PACKAGE_VERSION} built successfully for Python 3.12  =========="
