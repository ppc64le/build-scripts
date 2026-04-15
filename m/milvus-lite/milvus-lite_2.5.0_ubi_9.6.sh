#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : milvus-lite
# Version       : 2.5.0
# Source repo   : https://github.com/milvus-io/milvus-lite
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  : True
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
PACKAGE_URL="https://github.com/milvus-io/milvus-lite"
SCRIPT_PACKAGE_VERSION=v2.5.0
PACKAGE_NAME=milvus-lite
PACKAGE_DIR=milvus-lite/python
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PWDIR=$(pwd)

# 0. Install system tools
yum install -y git gcc-c++ gcc wget make python3.12 yum-utils \
               apr-devel perl openssl-devel automake autoconf libtool cmake \
               cargo libstdc++-static libaio libuuid-devel ncurses-devel \
               libtool m4 autoconf automake ninja-build zlib-devel \
               libffi-devel scl-utils openblas-devel xz patch \
               python3.12-devel python3.12-pip

yum install -y gcc-toolset-13
source /opt/rh/gcc-toolset-13/enable
gcc --version
echo "GCC Toolset 13 activated for milvus-lite build"

echo "Building OpenBLAS from source..."
export MAX_JOBS=$(nproc)

git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.32

make -j${MAX_JOBS} \
    TARGET=POWER9 \
    BUILD_BFLOAT16=1 \
    BINARY=64 \
    USE_OPENMP=1 \
    USE_THREAD=1 \
    NUM_THREADS=120 \
    DYNAMIC_ARCH=1 \
    INTERFACE64=0

make install

# Configure linker paths
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LIBRARY_PATH
export CPATH=/usr/local/include:$CPATH

echo "/usr/local/lib" >> /etc/ld.so.conf.d/openblas.conf
echo "/usr/local/lib64" >> /etc/ld.so.conf.d/openblas.conf
ldconfig

cd ..

# Ensure python3 refers to the distro’s default (if needed)
#ln -sf /usr/bin/python3.12 /usr/bin/python3 || true
#ln -sf /usr/bin/pip3.12    /usr/bin/pip3   || true
# -----------------------------------------------------------------------------
# 1. Set up Conan (for Milvus-Lite’s C++ deps)
# -----------------------------------------------------------------------------
python3.12 -m pip install --upgrade pip wheel setuptools conan==1.64.1

# -----------------------------------------------------------------------------
# 2. Build & install Texinfo (required by milvus-lite)
# -----------------------------------------------------------------------------
TEX_VER=7.1
echo "Downloading texinfo..."
for url in \
  https://mirrors.kernel.org/gnu/texinfo/texinfo-${TEX_VER}.tar.xz \
  https://ftpmirror.gnu.org/texinfo/texinfo-${TEX_VER}.tar.xz \
  https://ftp.gnu.org/gnu/texinfo/texinfo-${TEX_VER}.tar.xz
do
  wget "$url" && break
done
tar -xf "texinfo-${TEX_VER}.tar.xz"
pushd "texinfo-${TEX_VER}"
  ./configure && make -j2 && make install
popd
rm -rf "texinfo-${TEX_VER}"*

# -----------------------------------------------------------------------------
# 3. Build CMake 3.30.5 and register as a Conan package
# -----------------------------------------------------------------------------
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
 echo "cmake installed ...."
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
pushd /usr/local/cmake
    create_cmake_conanfile
    conan export-pkg . cmake/3.30.5@ -s os=Linux -s arch=$(uname -m) -f
popd
echo " exported completed successfully...."
# -----------------------------------------------------------------------------
# 5. Clone, patch & build Milvus-Lite
# -----------------------------------------------------------------------------
git clone "$PACKAGE_URL"
pushd milvus-lite
  git checkout "${SCRIPT_PACKAGE_VERSION}"
  git submodule update --init --recursive
  echo "Fetching patch via git..."
  git clone https://github.com/ppc64le/build-scripts.git /tmp/build-scripts
  cp /tmp/build-scripts/m/milvus-lite/milvus-lite-v2.5.0.patch /tmp/milvus-lite.patch
  echo "Applying patch..."
  patch -d thirdparty/milvus -p1 --forward < /tmp/milvus-lite-v2.5.0.patch
  echo "Patch applied successfully...."
  # Build Python wheel and install
  pushd python
    python3.12 -m pip install -r requirements.txt build
    python3.12 setup.py install
  popd
popd

echo "==========  All builds & installs completed successfully!  =========="
exit 0
