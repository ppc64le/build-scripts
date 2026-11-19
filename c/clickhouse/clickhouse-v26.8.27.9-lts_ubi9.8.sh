#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : clickhouse
# Version       : v26.8.27.9-lts
# Source repo   : https://github.com/ClickHouse/ClickHouse
# Tested on     : UBI 9.8
# Language      : C++
# Ci-Check      : False
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Prachi Gaonkar <prachi.gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Configuration
PACKAGE_NAME="clickhouse"
PACKAGE_ORG="ClickHouse"
SCRIPT_PACKAGE_VERSION="v26.8.27.9-lts"
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/ClickHouse"
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Install repos and dependencies
yum install -y yum-utils
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

dnf install -y git gcc gcc-c++ cmake ccache python3 ninja-build yasm gawk wget nasm xz gnupg \
    kernel-headers expect python3-jinja2 hostname \
    perl-FindBin perl-IPC-Cmd perl-File-Compare perl-File-Copy perl-Time-Piece perl-Pod-Html \
    clang-22.1.8-1.el9.ppc64le llvm-22.1.8-1.el9.ppc64le lld-22.1.8-1.el9.ppc64le libunwind libunwind-devel

export CC=clang
export CXX=clang++

# Install Rust
cd "$BUILD_HOME"
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
rustup toolchain install nightly-2026-03-22
rustup default nightly-2026-03-22
rustup component add rust-src
rustup target add powerpc64le-unknown-linux-gnu

# Clone
cd "$BUILD_HOME"
if ! git clone "$PACKAGE_URL" ClickHouse -b "$PACKAGE_VERSION"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd ClickHouse
git submodule update --init --recursive --jobs "$(nproc)"

# Apply main ppc64le patch
if ! git apply "${SCRIPT_PATH}/clickhouse-${SCRIPT_PACKAGE_VERSION}.patch"; then
    echo "------------------$PACKAGE_NAME:patch_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Patch_Fails"
    exit 1
fi

# Apply llvm-project (libunwind) patch
pushd contrib/llvm-project
if ! git apply "${SCRIPT_PATH}/clickhouse-${SCRIPT_PACKAGE_VERSION}-llvm-project.patch"; then
    echo "------------------$PACKAGE_NAME:llvm_patch_fails----------------------------------"
    exit 1
fi
popd

# Copy vm_sockets header required by sysroot on ppc64le
cp /usr/include/linux/vm_sockets.h \
    contrib/sysroot/linux-powerpc64le/powerpc64le-linux-gnu/libc/usr/include/linux/

# Detect Power10 CPU - pass as a cmake POWER10 option (ClickHouse blocks CMAKE_C_FLAGS)
POWER10_CMAKE_OPT=""
if grep -iq "POWER10" /proc/cpuinfo 2>/dev/null || lscpu 2>/dev/null | grep -iq "POWER10"; then
    echo "Power10 CPU detected - enabling POWER10=1 in cmake"
    POWER10_CMAKE_OPT="-D POWER10=1"
fi

# Build OpenSSL (bundled contrib)
pushd contrib/openssl
./config no-module
make -j"$(nproc)"
make install
popd

# Build ClickHouse
# Parallelism capped at 4 to limit peak RAM usage on a ~30 GB VM.
# Unset CFLAGS/CXXFLAGS so ClickHouse's PreLoad.cmake env-pollution check passes
# (the OpenSSL ./config step may export these into the environment).
unset CFLAGS CXXFLAGS LDFLAGS
BUILD_JOBS=4
ret=0
mkdir build
cd build
cmake -D CMAKE_BUILD_TYPE=RELWITHDEBINFO \
      -D ENABLE_TESTS=ON \
      -D ENABLE_OPENSSL_DYNAMIC=ON \
      -D ENABLE_CLICKHOUSE_KEEPER=ON \
      -D ENABLE_CLICKHOUSE_KEEPER_CONVERTER=ON \
      -D ENABLE_CLICKHOUSE_KEEPER_CLIENT=ON \
      ${POWER10_CMAKE_OPT} \
      .. || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi
ninja -j${BUILD_JOBS} || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Fix dynamic OpenSSL libs
rm -rf programs/libcrypto.so.3 programs/libssl.so.3
cp /usr/local/lib/libcrypto.so.3 /usr/local/lib/libssl.so.3 programs/

# Verify ClickHouse Keeper is built and runs
ret=0
./programs/clickhouse-keeper --version || ret=$?
test -x ./programs/clickhouse-keeper-client || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Unit tests
ret=0
./src/unit_tests_dbms || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
echo "Binaries available at [$BUILD_HOME/ClickHouse/build/programs/]"
exit 0
