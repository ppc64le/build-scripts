#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : milvus-lite
# Version       : v2.5.0
# Source repo   : https://github.com/milvus-io/milvus-lite
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : sai vikram kuppala <sai.vikram.kuppala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -x
################################################################################
# Configuration
################################################################################
 PACKAGE_NAME="milvus-lite"
 #PACKAGE_DIR="thirdparty/milvus"
 DEFAULT_VERSION="v2.5.0"
 PACKAGE_VERSION="${1:-$DEFAULT_VERSION}"
 PACKAGE_URL="https://github.com/milvus-io/milvus-lite"
 WORKDIR="$(pwd)"
 SCRIPT_PATH=$(dirname $(realpath $0))
 OPENBLAS_PREFIX="/opt/OpenBLAS"
 RUST_TOOLCHAIN="1.73"

################################################################################
# Helpers
################################################################################
log()   { echo -e "\e[1;32m[INFO]\e[0m $*"; }
warn()  { echo -e "\e[1;33m[WARN]\e[0m $*"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; exit 1; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (or via sudo)."
  fi
}

################################################################################
# 1. System prerequisites
################################################################################
install_system_deps() {
  log "Installing system packages via yum…"
  yum update -y
  yum remove -y gcc-toolset-13
 echo "installing dependencies"
 yum install -y sudo xz wget perl git which m4 automake autoconf libtool patch \
    ninja-build pkgconfig gcc gcc-c++ gcc-gfortran openssl openssl-devel \
    libstdc++-static python3-pip python-devel cargo libaio libuuid-devel \
    ncurses-devel zlib-devel xz-devel libffi-devel openblas-devel scl-utils
pip3 install wheel conan==1.64.1 setuptools==70.0.0
  # texinfo
  if ! command -v makeinfo &>/dev/null; then
    log "Building & installing texinfo from source…"
    cd /usr/local/src
    wget -q https://ftp.gnu.org/gnu/texinfo/texinfo-7.1.tar.xz
    tar xf texinfo-7.1.tar.xz && cd texinfo-7.1
    ./configure --prefix=/usr/local
    make -j2
    make install
    cd ..
  else
    log "texinfo already installed"
  fi
}


################################################################################
# 2. Build OpenBLAS for POWER9
################################################################################
build_openblas() {
  log "Cloning OpenBLAS…"
  cd /usr/local/src
  rm -rf OpenBLAS
  git clone https://github.com/xianyi/OpenBLAS.git
  cd OpenBLAS

  log "Cleaning previous builds…"
  make clean

  log "Building OpenBLAS (shared/static, skipping tests)…"
    make TARGET=POWER9 \
       DYNAMIC_ARCH=1 \
       USE_OPENMP=0 \
       SHARED=1 \
       NO_NEON=1 \
       NO_LAPACK_TEST=1 \
       NO_LAPACKE=1 \
       -j2

  log "Installing OpenBLAS to ${OPENBLAS_PREFIX}…"
  make PREFIX="${OPENBLAS_PREFIX}" install

  log "Cleaning up OpenBLAS source…"
  cd /usr/local/src && rm -rf OpenBLAS

  log "Exporting OpenBLAS environment variables…"
  export OPENBLAS_DIR="${OPENBLAS_PREFIX}"
  export LD_LIBRARY_PATH="${OPENBLAS_DIR}/lib:${LD_LIBRARY_PATH:-}"
  export CFLAGS="-I${OPENBLAS_DIR}/include"
  export LDFLAGS="-L${OPENBLAS_DIR}/lib"
  export PKG_CONFIG_PATH="${OPENBLAS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
}

################################################################################
# 2.1 Remove OpenSSL-FIPS if present
################################################################################
remove_fips() {
  if rpm -qf /usr/lib64/ossl-modules/fips.so &>/dev/null; then
    log "Removing OpenSSL-FIPS provider…"
    rpm -e --nodeps openssl-fips-provider-so-3.0.7-6.el9_5.ppc64le || true
  else
    log "OpenSSL-FIPS provider not present; skipping"
  fi
  log "Cleaning yum cache and updating…"
  yum clean all
  yum update -y
}

################################################################################
# 3. Environment flags for OpenSSL and gRPC
################################################################################
export_openssl_flags() {
  log "Exporting OpenSSL and gRPC build flags…"
  export CPPFLAGS="-DOPENSSL_64_BIT"
  export CFLAGS="$CPPFLAGS"
  export CXXFLAGS="$CPPFLAGS"
  export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
}

################################################################################
# 4. Setup Rust toolchain
################################################################################
setup_rust() {
  if ! command -v rustc &>/dev/null || [[ "$(rustc --version)" != *"${RUST_TOOLCHAIN}"* ]]; then
    log "Installing Rust ${RUST_TOOLCHAIN} via rustup…"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
      sh -s -- -y --default-toolchain="${RUST_TOOLCHAIN}"
    source "$HOME/.cargo/env"
    rustup update
    rustup default stable
  else
    log "Rust ${RUST_TOOLCHAIN} already installed"
  fi
  cargo --version
}


################################################################################
# 6. Python & Conan environment
################################################################################
install_python_deps() {
  log "Installing pip  + core Python packages…"
  python3 -m pip install --upgrade pip
  python3 -m pip install \
    wheel \
    meson==1.8.2\
    numpy==1.26.4\
    conan==1.64.1\
    scipy==1.13.1\
    setuptools==70.0.0\
    grpcio==1.64.1\
    pandas==2.3.1\
    protobuf==6.31.1\
    python-dotenv==1.1.1\
    ujson==5.10.0
}
# Install CMake , canon setup and  build
install_cmake() {
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

# mkdir -p "${WORKDIR}/workspace"
# cd "${WORKDIR}/workspace"

#Install cmake
cd $wdir

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
echo "installing"
make install -j2
export PATH=/usr/local/cmake/bin:$PATH
cmake --version
cd ..
cd $WORKDIR
echo "cloning"
#Clone the package
log "Cloning milvus-lite (${PACKAGE_VERSION})…"
rm -rf milvus-lite
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout  ${PACKAGE_VERSION}
git submodule update --init --recursive
PATCH_FILE="${SCRIPT_PATH}/${PACKAGE_NAME}-${PACKAGE_VERSION}.patch"
#build the package
pushd /usr/local/cmake
create_cmake_conanfile
log "Installing Conan dependencies…"
# if ! conan remote list | grep -q '^conancenter '; then
#   conan remote add conancenter https://center.conan.io
#   log "Added conancenter remote"
# else
#   log "conancenter remote already exists, skipping"
# fi

#conan remote list | grep -q conan-center || \
# conan remote add conan-center https://center.conan.io
 cd /milvus-lite || { echo "Directory /milvus-lite does not exist! Exiting."; exit 1; }
 log "echo working dir ..., $WORKDIR"
if [[ -f "${PATCH_FILE}" ]]; then
    log "Applying patch for canon file.py ${PATCH_FILE}…"
    patch -p1 < "${PATCH_FILE}"
else
    warn "Patch file not found: ${PATCH_FILE}, continuing without it."
fi
  log "canon file patch was successfully applied..."


# cd ${PACKAGE_DIR}
# if [[ -f "${PATCH_FILE}" ]]; then
#   log "Applying patch for tokenzier.h ${PATCH_FILE}…"
#     git apply "${PATCH_FILE}"
# else
#     warn "Patch file not found: ${PATCH_FILE}, continuing without it."
# fi
#   log "tokenzier file patch was successfully applied..."

# log "echo working dir 3333 ..., $WORKDIR"

conan install "${WORKDIR}/milvus-lite" \
    --build=missing \
    -s build_type=Release \
    -s compiler.libcxx=libstdc++11 \
    --update
conan profile update settings.compiler.libcxx=libstdc++11 default
conan export-pkg . cmake/${CMAKE_REQUIRED_VERSION}@ -s os="Linux" -s arch="ppc64le" -f
popd
export VCPKG_FORCE_SYSTEM_BINARIES=1
mkdir -p $HOME/.cargo/bin/
echo "installing dependencies"
pip install -r requirements.txt
pip install build

echo "installing package"
# Install the package
if ! python3 setup.py install; then
    echo "------------------$PACKAGE_NAME: Installation failed ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Installation_Failure"
    exit 1
fi
pip install -U pymilvus==2.5.12
echo "building wheel"
#build wheel
if ! python3 -m build --wheel --no-isolation --outdir="$WORKDIR/"; then
    echo "------------------$PACKAGE_NAME: Wheel_build failed ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Wheel_build_Failure"
    exit 1
else
    echo "------------------$PACKAGE_NAME: Installation and build_wheel successful ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Installation_and_build_wheel_Success"
    exit 0
fi
}

################################################################################
# Main
################################################################################
main() {
  install_system_deps
  build_openblas
  remove_fips
  export_openssl_flags
  setup_rust
  install_python_deps
  install_cmake
  log "All done — milvus-lite ${PACKAGE_VERSION} is built and wheel is in ${WORKDIR}"
}

main "$@"
