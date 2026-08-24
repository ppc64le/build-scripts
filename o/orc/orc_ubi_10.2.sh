#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : orc
# Version          : 2.3.1
# Source repo      : https://github.com/apache/orc
# Tested on        : UBI:10.2
# Language         : Python, C
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
PACKAGE_NAME=orc
PACKAGE_VERSION=${1:-2.3.1}
PACKAGE_URL=https://github.com/apache/orc
CURRENT_DIR=$(pwd)

# ---------------------------------------------------------------------------
# System dependencies
# NOTE: Python packages MUST be listed first — the create_wheel_wrapper.sh
#       strips them and manages the Python install inside its own venv.
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    wget git make cmake binutils lz4-devel zlib-devel \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-binutils \
    ninja-build tzdata

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15
# UBI 10 removed SCL — the `source enable` script does NOT exist.
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi
echo "Using gcc: $(gcc --version | head -1)"

export CC=$(which gcc)
export CXX=$(which g++)
export GCC=$CC
export GXX=$CXX

# ---------------------------------------------------------------------------
# Python build tools  (always via pip, never via yum)
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build ninja

# ---------------------------------------------------------------------------
# ZSTD
# ---------------------------------------------------------------------------
echo " --------------------------------------------------- Installing ZSTD --------------------------------------------------- "

cd "$CURRENT_DIR"
if [[ ! -d zstd ]]; then
    git clone https://github.com/facebook/zstd.git
fi
cd zstd
make -j"$(nproc)"
make install

export ZSTD_HOME=/usr/local
export CMAKE_PREFIX_PATH=$ZSTD_HOME:$CMAKE_PREFIX_PATH
export LD_LIBRARY_PATH=$ZSTD_HOME/lib:$LD_LIBRARY_PATH

echo " --------------------------------------------------- ZSTD Successfully Installed --------------------------------------------------- "

# ---------------------------------------------------------------------------
# Snappy
# ---------------------------------------------------------------------------
echo " --------------------------------------------------- Installing snappy --------------------------------------------------- "

cd "$CURRENT_DIR"
if [[ ! -d snappy ]]; then
    git clone -b 1.2.2 https://github.com/google/snappy
fi
cd snappy
git submodule update --init

mkdir -p local/snappy
mkdir -p build
cd build

cmake .. \
    -DBUILD_SHARED_LIBS=ON \
    -DSNAPPY_BUILD_STATIC=OFF \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib64
make -j"$(nproc)"
make install

echo " --------------------------------------------------- Snappy Successfully Installed --------------------------------------------------- "

# ---------------------------------------------------------------------------
# abseil-cpp (dependency for protobuf)
# ---------------------------------------------------------------------------
echo " --------------------------------------------------- Cloning abseil-cpp --------------------------------------------------- "

cd "$CURRENT_DIR"
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"

if [[ ! -d abseil-cpp ]]; then
    git clone "$ABSEIL_URL" -b "$ABSEIL_VERSION"
fi

echo " --------------------------------------------------- abseil-cpp cloned successfully --------------------------------------------------- "

# ---------------------------------------------------------------------------
# libprotobuf (dependency for orc)
# ---------------------------------------------------------------------------
cd "$CURRENT_DIR"
mkdir -p "$CURRENT_DIR/local/libprotobuf"
LIBPROTO_INSTALL="$CURRENT_DIR/local/libprotobuf"

echo " --------------------------------------------------- Cloning protobuf --------------------------------------------------- "

if [[ ! -d protobuf ]]; then
    git clone https://github.com/protocolbuffers/protobuf
fi
cd protobuf
git checkout v4.25.8
git submodule update --init --recursive
rm -rf ./third_party/googletest || true
rm -rf ./third_party/abseil-cpp || true
cp -r "$CURRENT_DIR/abseil-cpp" ./third_party/

mkdir -p build
cd build

cmake -G "Ninja" \
    "${CMAKE_ARGS}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_INSTALL_PREFIX="$LIBPROTO_INSTALL" \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_LIBUPB=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER="module" \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..

cmake --build . --verbose
cmake --install .

cd "$CURRENT_DIR"
export PATH="$LIBPROTO_INSTALL/bin:$PATH"
protoc --version

echo " --------------------------------------------------- libprotobuf installed successfully --------------------------------------------------- "

export LD_LIBRARY_PATH="$CURRENT_DIR/local/abseil-cpp/lib:$LD_LIBRARY_PATH"
export CMAKE_PREFIX_PATH="$CURRENT_DIR/local/abseil-cpp:$CMAKE_PREFIX_PATH"
export PROTOBUF_PREFIX="$CURRENT_DIR/local/libprotobuf"

# ---------------------------------------------------------------------------
# Clone & checkout orc
# ---------------------------------------------------------------------------
cd "$CURRENT_DIR"
if [[ ! -d "$PACKAGE_NAME" ]]; then
    git clone "$PACKAGE_URL"
fi
cd "$PACKAGE_NAME"

if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# Download pyproject.toml and patch from the build-scripts repository
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/orc/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/$(echo "$PACKAGE_VERSION" | sed 's/^v//')/g" pyproject.toml
echo "--------------------------replaced version in pyproject.toml--------------------------"

# Inline patches (replaces orc.patch — applied idempotently regardless of line shift)
#
# Patch 1 — CMakeLists.txt: clear WARN_FLAGS after the compiler-specific block so
#            ppc64le builds are not hit by x86/MSVC warning flags.
# Patch 2 — c++/src/CMakeLists.txt: build orc as a SHARED library instead of STATIC
#            so auditwheel can inspect and repair the resulting .so.
python3.14 - <<'PYEOF'
from pathlib import Path

# --- Patch 1: CMakeLists.txt ---
p = Path("CMakeLists.txt")
src = p.read_text()
marker = 'set(WARN_FLAGS "")'
anchor = "if (BUILD_CPP_ENABLE_METRICS)"
if marker not in src:
    src = src.replace(anchor, f'{marker}\n\n{anchor}', 1)
    p.write_text(src)
    print("CMakeLists.txt: patched WARN_FLAGS reset OK")
else:
    print("CMakeLists.txt: already patched — skipping")

# --- Patch 2: c++/src/CMakeLists.txt ---
p2 = Path("c++/src/CMakeLists.txt")
src2 = p2.read_text()
old2 = "add_library (orc STATIC ${SOURCE_FILES})"
new2 = "add_library (orc ${SOURCE_FILES})"
if old2 in src2:
    p2.write_text(src2.replace(old2, new2, 1))
    print("c++/src/CMakeLists.txt: patched STATIC→shared OK")
else:
    print("c++/src/CMakeLists.txt: already patched — skipping")
PYEOF

# ---------------------------------------------------------------------------
# Build orc C library via CMake + Ninja
# ---------------------------------------------------------------------------
mkdir -p prefix
export PREFIX=$(pwd)/prefix
mkdir -p build && cd build

export HOST=$(uname)-$(uname -m)

CPPFLAGS="${CPPFLAGS} -Wl,-rpath,$VIRTUAL_ENV_PATH/**/lib"

# Unset GTEST_HOME so orc's ThirdpartyToolchain.cmake takes the FetchContent
# branch. Also disable find_package(GTest) so CMake cannot pick up the system
# libgtest/libgmock (built with system GCC) which would cause an ABI mismatch
# with gcc-toolset-15.
unset GTEST_HOME

# Note: -DBUILD_JAVA=False — orc is a build-time dependency of arrow which
# only needs the C++ components. Set to True if Java components are required.
cmake "${CMAKE_ARGS}" \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_JAVA=False \
    -DLZ4_HOME=/usr \
    -DZLIB_HOME=/usr \
    -DZSTD_HOME=/usr \
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
    -DProtobuf_ROOT="$PROTOBUF_PREFIX" \
    -DPROTOBUF_HOME="$PROTOBUF_PREFIX" \
    -DPROTOBUF_EXECUTABLE="$PROTOBUF_PREFIX/bin/protoc" \
    -DSNAPPY_HOME=/usr \
    -DBUILD_LIBHDFSPP=NO \
    -DBUILD_CPP_TESTS=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_GTest=ON \
    -DORC_PREFER_STATIC_GMOCK=OFF \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_C_COMPILER="$(type -p "${CC}")" \
    -DCMAKE_CXX_COMPILER="$(type -p "${CXX}")" \
    -DCMAKE_C_FLAGS="$CFLAGS" \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-unused-parameter" \
    -GNinja ..

if ! (ninja && ninja install); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd ..
mkdir -p "local/$PACKAGE_NAME"
cp -r prefix/* "local/$PACKAGE_NAME"

# Export library paths needed by auditwheel / the wheel build
export LD_LIBRARY_PATH="$PREFIX/lib:$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"

# ---------------------------------------------------------------------------
# Build Python wheel
# Wheel is built explicitly here because the CMake paths set above are
# required at build time and will not be available to create_wheel_wrapper.sh.
# ---------------------------------------------------------------------------
echo "---------------------------------------------------Building the wheel--------------------------------------------------"
python3.14 -m pip install --upgrade build setuptools wheel
python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
echo "----------------------------------------------Testing pkg-------------------------------------------------------"
cd build

if ! (ninja test); then
    ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
    export TZDIR=/usr/share/zoneinfo
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
