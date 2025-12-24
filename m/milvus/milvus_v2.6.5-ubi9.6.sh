#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package           : milvus
# Version           : v2.6.5
# Source repo       : https://github.com/milvus-io/milvus.git
# Tested on         : UBI 9.6
# Language          : C++, Go
# Ci-Check          : False
# Script License    : Apache License, Version 2.0
# Maintainer        : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on the given
#                     platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution.
#
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
SCRIPT_PACKAGE_VERSION=v2.6.5
PACKAGE_NAME=milvus
PACKAGE_VERSION=${SCRIPT_PACKAGE_VERSION}
PACKAGE_URL=https://github.com/milvus-io/${PACKAGE_NAME}
CMAKE_VERSION=3.30.5
CMAKE_REQUIRED_VERSION=3.30.5
PYTHON_VERSION=3.10.2
GO_VERSION=1.24.11
WDIR=$(pwd)
SCRIPT_PATH=$(dirname $(realpath $0))
APPLYMCPU=0

# -----------------------------------------------------------------------------
# Argument Parsing for Power10.
# -----------------------------------------------------------------------------
for i in "$@"; do
  case $i in
    --power10)
      APPLYMCPU=1
      echo "Optimizing for Power10"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 3
      ;;
    *)
      PACKAGE_VERSION=$i
      echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"
      ;;
  esac
done

# -----------------------------------------------------------------------------
# System Limits
# -----------------------------------------------------------------------------
ulimit -n 65536
ulimit -f unlimited

# -----------------------------------------------------------------------------
# STEP 1: Enable Repositories
# -----------------------------------------------------------------------------
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os

rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# -----------------------------------------------------------------------------
# STEP 2: Install System Dependencies
# -----------------------------------------------------------------------------
yum install -y openssl openssl-devel \
  --exclude=openssl-fips-provider* --allowerasing --nobest

yum install -y python3.12 python3.12-devel python3.12-pip \
  --exclude=openssl-fips-provider* --allowerasing --nobest

yum install -y --allowerasing \
  git gcc gcc-c++ make yum-utils sudo zip tar pkg-config \
  perl-IPC-Cmd perl-Digest-SHA perl-FindBin perl-File-Compare \
  wget rust apr-devel perl automake autoconf libtool cmake which \
  perl-open.noarch cargo libstdc++-static

yum install -y --allowerasing \
  libaio libuuid-devel ncurses-devel gfortran patchelf texinfo diffutils m4 \
  ninja-build zlib-devel java-11-openjdk-devel lcov \
  libffi-devel openblas-devel hdf5-devel sqlite-devel \
  bzip2-devel xz-devel xz patch lzo lzo-devel

# -----------------------------------------------------------------------------
# STEP 3: Python Setup
# -----------------------------------------------------------------------------
update-alternatives --install /usr/bin/python python /usr/bin/python3.12 2
update-alternatives --install /usr/bin/pip pip /usr/bin/pip3.12 2

# -----------------------------------------------------------------------------
# STEP 4: Java Setup
# -----------------------------------------------------------------------------
export JAVA_HOME
JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JRE_HOME="${JAVA_HOME}/jre"
export PATH="${JAVA_HOME}/bin:${PATH}"

# -----------------------------------------------------------------------------
# STEP 5: Build CMake
# -----------------------------------------------------------------------------
cd "${WDIR}"

if [ ! -d "cmake-${CMAKE_VERSION}" ] || [ -z "$(ls -A cmake-${CMAKE_VERSION})" ]; then
  wget -c https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
  tar -xzf cmake-${CMAKE_VERSION}.tar.gz
  rm -f cmake-${CMAKE_VERSION}.tar.gz
fi

cd cmake-${CMAKE_VERSION}
./bootstrap --prefix=/usr/local/cmake --parallel=2 -- \
  -DBUILD_TESTING=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_USE_OPENSSL=ON

make install -j$(nproc)
export PATH=/usr/local/cmake/bin:${PATH}
cmake --version

# -----------------------------------------------------------------------------
# STEP 6: Python Build
# -----------------------------------------------------------------------------
cd "${WDIR}"
if [ ! -d "Python-${PYTHON_VERSION}" ]; then
  wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
  tar xzf Python-${PYTHON_VERSION}.tgz
fi

cd Python-${PYTHON_VERSION}
./configure --enable-loadable-sqlite-extensions
make -j$(nproc)
make altinstall

ln -sf "$(which python3.10)" /usr/bin/python
ln -sf "$(which pip3.10)" /usr/bin/pip3

# -----------------------------------------------------------------------------
# STEP 7: Python Dependencies
# -----------------------------------------------------------------------------
pip3 install --upgrade pip
pip3 install conan==1.64.1 setuptools==59.5.0

# -----------------------------------------------------------------------------
# STEP 8: Go Installation
# -----------------------------------------------------------------------------
cd "${WDIR}"
if [ ! -f "/usr/local/go/bin/go" ]; then
  wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
  rm -rf /usr/local/go
  tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
fi

export PATH=/usr/local/go/bin:${PATH}:${HOME}/go/bin

# -----------------------------------------------------------------------------
# STEP 9: Clone Milvus
# -----------------------------------------------------------------------------
cd "${WDIR}"
rm -rf "${PACKAGE_NAME}"
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION} -b ${PACKAGE_VERSION}

# -----------------------------------------------------------------------------
# STEP 10: Apply Patch
# -----------------------------------------------------------------------------
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch

# -----------------------------------------------------------------------------
# STEP 11: Power10 Optimization
# -----------------------------------------------------------------------------
if [ "${APPLYMCPU}" -eq 1 ]; then
  sed -i '53d' internal/core/CMakeLists.txt
  sed -i '53i set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -mcpu=power10")' \
    internal/core/CMakeLists.txt
fi

# -----------------------------------------------------------------------------
# STEP 12: Conan Setup
# -----------------------------------------------------------------------------
mkdir -p /usr/local/cmake
cat <<'EOF' >/usr/local/cmake/conanfile.py
from conans import ConanFile, tools
class CmakeConan(ConanFile):
    name = "cmake"
    version = "3.30.5"
    package_type = "application"
    settings = "os", "arch"
    def package(self):
        self.copy("*")
        self.requires("cmake/3.30.5")
    def package_info(self):
        self.cpp_info.libs = tools.collect_libs(self)
EOF

pushd /usr/local/cmake >/dev/null
conan export-pkg . cmake/${CMAKE_REQUIRED_VERSION}@ -s os=Linux -s arch=ppc64le
conan profile update settings.compiler.libcxx=libstdc++11 default
popd >/dev/null

# -----------------------------------------------------------------------------
# STEP 13: Environment Variables
# -----------------------------------------------------------------------------
export VCPKG_FORCE_SYSTEM_BINARIES=1
export MILVUS_JEMALLOC_BUILD_VERSION=5.3.0
export JEMALLOC_CONF="--disable-prof"
export JEMALLOC_CONFIGURE_FLAGS="--disable-prof"
export LD_LIBRARY_PATH="${WDIR}/milvus/lib:${LD_LIBRARY_PATH:-}"
export CXXFLAGS="-Wno-psabi -Wno-error"
export CFLAGS="-Wno-psabi -Wno-error"

# -----------------------------------------------------------------------------
# STEP 14: Rust Setup
# -----------------------------------------------------------------------------
if [ ! -f "${HOME}/.cargo/env" ]; then
  curl https://sh.rustup.rs -sSf | bash -s -- -y
fi
source "${HOME}/.cargo/env"

# -----------------------------------------------------------------------------
# STEP 15: Build & Test Milvus.
# -----------------------------------------------------------------------------
cd "${WDIR}/${PACKAGE_NAME}"

BUILD_RET=0
make -j$(nproc) || BUILD_RET=$?
if [ "${BUILD_RET}" -ne 0 ]; then
  echo "ERROR: Build failed with exit code ${BUILD_RET}"
  exit 1
fi
# Run CPP Test.
make test-cpp -j$(nproc) || BUILD_RET=$?
if [ "${BUILD_RET}" -ne 0 ]; then
  echo "ERROR: Test failed with exit code ${BUILD_RET}"
  exit 2
fi

# -----------------------------------------------------------------------------
# Binary/Lib configuration
# -----------------------------------------------------------------------------
export MILVUS_BIN="${WDIR}/${PACKAGE_NAME}/bin/milvus"
mkdir -p /milvus/internal/core/output/lib
ln -sf /milvus/internal/core/output/lib64/libmilvus_core.so \
       /milvus/internal/core/output/lib/libmilvus_core.so
chmod +x /milvus/internal/core/output/lib64/libmilvus_core.so

#Start Milvus dev stack
#cd $wdir/${PACKAGE_NAME}/
#docker compose -f ./deployments/docker/dev/docker-compose.yml up -d
#sleep 10

#Go unit tests
#cd $wdir/${PACKAGE_NAME}/
#make test-go -j$(nproc) || ret=$?
#if [ "$ret" -ne 0 ]
#then
#        echo "Go Tests fail."
#        exit 2
#fi

# -----------------------------------------------------------------------------
# Final Setup.
# -----------------------------------------------------------------------------
echo "Milvus binary: ${MILVUS_BIN}"
echo "Golang tests were skipped"
echo "[SUCCESS] Milvus ${PACKAGE_VERSION} build and test completed successfully."
exit 0
