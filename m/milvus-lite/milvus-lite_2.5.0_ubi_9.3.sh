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
PACKAGE_URL_OTEL=https://github.com/open-telemetry/opentelemetry-cpp
OTEL_VERSION=${1:-v1.15.0}

SCRIPT_PATH=$(dirname "$(realpath "$0")")
MILVUS_VERSION=v2.5.0
MILVUS_URL="https://github.com/milvus-io/milvus-lite"

# 0. Install system tools
yum install -y git gcc-c++ gcc wget make python3 yum-utils \
               apr-devel perl openssl-devel automake autoconf libtool cmake \
               cargo libstdc++-static libaio libuuid-devel ncurses-devel \
               libtool m4 autoconf automake ninja-build zlib-devel \
               libffi-devel scl-utils openblas-devel xz patch \
               python3-devel python3-pip

# Ensure python3 refers to the distro’s default (if needed)
ln -sf /usr/bin/python3.12 /usr/bin/python3 || true
ln -sf /usr/bin/pip3.12    /usr/bin/pip3   || true

# -----------------------------------------------------------------------------
# 1. Build & install googletest (gtest)
# -----------------------------------------------------------------------------
git clone https://github.com/google/googletest.git
pushd googletest
  git checkout v1.14.0
  mkdir build && cd build
  cmake .. && make -j$(nproc) && make install
popd

# -----------------------------------------------------------------------------
# 2. Build & install Google Benchmark
# -----------------------------------------------------------------------------
git clone https://github.com/google/benchmark.git
pushd benchmark
  cmake -E make_directory build
  cmake -E chdir build \
        cmake -DBENCHMARK_DOWNLOAD_DEPENDENCIES=on \
              -DCMAKE_BUILD_TYPE=Release \
              ..
  cmake --build build --config Release -- -j$(nproc)
  cmake -E chdir build ctest --build-config Release
  cmake --build build --config Release --target install
popd

# -----------------------------------------------------------------------------
# 3. Clone, build & install OpenTelemetry-CPP
# -----------------------------------------------------------------------------
git clone --recursive "$PACKAGE_URL_OTEL"
pushd opentelemetry-cpp
  git checkout "$OTEL_VERSION"
  mkdir build && cd build
  cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTS=OFF
  cmake --build . -- -j$(nproc)
  cmake --install .    # installs into /usr/local by default
popd

# -----------------------------------------------------------------------------
# 4. Set up Conan (for Milvus-Lite’s C++ deps)
# -----------------------------------------------------------------------------
python3 -m pip install --upgrade pip wheel setuptools conan==1.64.1
conan profile update settings.compiler.libcxx=libstdc++11 default

# -----------------------------------------------------------------------------
# 5. Build & install Texinfo (required by milvus-lite)
# -----------------------------------------------------------------------------
TEX_VER=7.1
wget "https://ftp.gnu.org/gnu/texinfo/texinfo-${TEX_VER}.tar.xz"
tar -xf "texinfo-${TEX_VER}.tar.xz"
pushd "texinfo-${TEX_VER}"
  ./configure && make -j2 && make install
popd
rm -rf "texinfo-${TEX_VER}"*

# -----------------------------------------------------------------------------
# 6. Build CMake 3.30.5 and register as a Conan package
# -----------------------------------------------------------------------------
CMAKE_VERSION=3.30.5
mkdir -p workspace && pushd workspace
  wget -c "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz"
  tar -xzf "cmake-${CMAKE_VERSION}.tar.gz"
  pushd "cmake-${CMAKE_VERSION}"
    ./bootstrap --prefix=/usr/local/cmake \
                -- -DBUILD_TESTING=OFF -DCMAKE_USE_OPENSSL=ON
    make -j2 && make install
  popd
popd
export PATH=/usr/local/cmake/bin:$PATH

cat <<EOF > /usr/local/cmake/conanfile.py
from conans import ConanFile, tools
class CmakeConan(ConanFile):
    name = "cmake"
    version = "${CMAKE_VERSION}"
    package_type = "application"
    settings = "os", "arch"
    def package(self):
        self.copy("*")
    def package_info(self):
        self.cpp_info.libs = tools.collect_libs(self)
EOF

conan export-pkg /usr/local/cmake \
                 cmake/${CMAKE_VERSION}@ \
                 -s os=Linux \
                 -s arch=$(uname -m) \
                 -f

# -----------------------------------------------------------------------------
# 7. Clone, patch & build Milvus-Lite
# -----------------------------------------------------------------------------
git clone "$MILVUS_URL"
pushd milvus-lite
  git checkout "${MILVUS_VERSION}"
  git submodule update --init --recursive

  PATCH_FILE="${SCRIPT_PATH}/milvus-lite-${MILVUS_VERSION}.patch"
  if [[ -f "$PATCH_FILE" ]]; then
    echo "Applying patch: $PATCH_FILE"
    patch -d thirdparty/milvus -p1 --forward < "$PATCH_FILE"
  else
    echo "Warning: patch not found at $PATCH_FILE"
  fi

  # Build Python wheel and install
  pushd python
    python3 -m pip install -r requirements.txt build
    python3 setup.py install
    python3 -m build --wheel --no-isolation --outdir "${PWD}/dist"
  popd
popd

echo "==========  All builds & installs completed successfully!  =========="
exit 0
