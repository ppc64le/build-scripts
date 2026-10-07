#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : mooncake-transfer-engine-rocm
# Version       : v0.3.13.post1
# Source repo   : https://github.com/kvcache-ai/Mooncake
# Tested on     : UBI:10 (ppc64le)
# Language      : Python, C++, HIP
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Daniel Schenker <daniel.schenker@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
#
# ROCm installation mode (ROCM_INSTALL_MODE env var):
#   rpms   (default) - Install ROCm RPMs from a provided repo URL
#   path             - Assume ROCm is already present; use ROCM_PATH as-is
#
# The Mooncake transfer engine is built with AMD HIP/ROCm support enabled
# (-DUSE_HIP=ON) via scikit-build-core, which drives the CMake + pybind11
# build.  Go, SPDK, etcd, and all other optional components are disabled so
# the wheel is a lean transfer-engine-only package.
#
# Usage:
#   ./mooncake_v0.3.13.post1_rocm_ubi_10.sh [v0.3.13.post1]
#
# Environment variables honoured (can be set before running):
#   PACKAGE_VERSION  - Mooncake tag to build (default: v0.3.13.post1)
#   ROCM_INSTALL_MODE - rpms (default) or path
#   ROCM_PATH        - Path to ROCm installation (default: /opt/rocm)
#   ROCM_REPO_URL    - RPM repo baseurl for ROCm
#   DEVPI_INDEX      - IBM ppc64le devpi wheel index URL
#                      (default: https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple)
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=mooncake-transfer-engine-rocm
PACKAGE_VERSION=${1:-v0.3.13.post1}
PACKAGE_URL=https://github.com/kvcache-ai/Mooncake.git
CURRENT_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

ROCM_INSTALL_MODE=${ROCM_INSTALL_MODE:-"rpms"}   # rpms | path
ROCM_REPO_URL=${ROCM_REPO_URL:-"https://public.dhe.ibm.com/software/server/POWER/Linux/AMD/ROCm/RHEL/10/ppc64le"}
ROCM_PATH=${ROCM_PATH:-/opt/rocm}

DEVPI_INDEX=${DEVPI_INDEX:-"https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple"}

if [[ "$ROCM_INSTALL_MODE" != "rpms" && "$ROCM_INSTALL_MODE" != "path" ]]; then
    echo "ERROR: ROCM_INSTALL_MODE must be one of: rpms, path"
    exit 1
fi

echo "=== Mooncake Transfer Engine ROCm Build ==="
echo "  PACKAGE_VERSION  : $PACKAGE_VERSION"
echo "  ROCM_INSTALL_MODE: $ROCM_INSTALL_MODE"
echo "  ROCM_PATH        : $ROCM_PATH"
echo "  DEVPI_INDEX      : $DEVPI_INDEX"
echo "==========================================="

# ---------------------------------------------------------------------------
# Install system build dependencies
# ---------------------------------------------------------------------------

# Python packages must appear first (wrapper script requirement).
# Notes on unavailable packages:
#   libdrm       - not in UBI 10 repo; built from source below
#   jsoncpp-devel - not in any RHEL 10 / EPEL 10 repo; built from source below
#   boost-devel  - not needed: boost is not linked by the transfer engine when
#                  store/etcd/redis components are disabled
#   protobuf-devel - not in RHEL 10; only needed for USE_ETCD_LEGACY (disabled)
#   liburing-devel - only needed for USE_TENT (disabled)
yum install -y python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    git make wget cmake ninja-build \
    rdma-core-devel \
    glog-devel \
    gflags-devel \
    libunwind-devel \
    numactl-devel \
    openssl-devel \
    yaml-cpp-devel \
    libcurl-devel \
    hiredis-devel \
    jemalloc-devel \
    msgpack-devel \
    libzstd-devel \
    pkgconf-pkg-config \
    elfutils-libelf-devel \
    patchelf \
    xxhash-devel \
    libbsd-devel \
    meson

# Configure GCC Toolset 15
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

# Use Python 3.12 for the build so all produced wheels are cp312
PYTHON=python3.12

# ---------------------------------------------------------------------------
# Build libdrm from source
# libdrm is not available in the UBI 10 package repository.  We clone the
# upstream freedesktop.org release, build it with meson, and install it into
# /usr/local so every subsequent build step can find it via pkg-config.
# ---------------------------------------------------------------------------
LIBDRM_VERSION=${LIBDRM_VERSION:-"libdrm-2.4.124"}
LIBDRM_URL="https://gitlab.freedesktop.org/mesa/drm.git"

echo "Building libdrm ${LIBDRM_VERSION} from source"
if [ -d "${CURRENT_DIR}/drm" ]; then
    echo "drm directory already exists, reusing."
    cd "${CURRENT_DIR}/drm"
    git checkout "$LIBDRM_VERSION"
else
    if ! git clone --branch "$LIBDRM_VERSION" --depth 1 "$LIBDRM_URL" "${CURRENT_DIR}/drm"; then
        echo "ERROR: Failed to clone libdrm ${LIBDRM_VERSION}"
        exit 1
    fi
    cd "${CURRENT_DIR}/drm"
fi

meson setup build \
    --prefix=/usr/local \
    --buildtype=release \
    -Damdgpu=enabled \
    -Dradeon=enabled \
    -Dintel=disabled \
    -Dnouveau=disabled \
    -Dvmwgfx=disabled \
    -Dtests=false

ninja -C build
ninja -C build install

# Make the freshly installed libdrm visible to pkg-config and the linker
export PKG_CONFIG_PATH="/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="/usr/local/lib64:/usr/local/lib:${LD_LIBRARY_PATH:-}"
echo "libdrm installed: $(pkg-config --modversion libdrm)"

cd "${CURRENT_DIR}"

# ---------------------------------------------------------------------------
# Build jsoncpp from source
# jsoncpp-devel is not available in any RHEL 10 / EPEL 10 repository.
# The Mooncake CMake build requires JsonCpp headers and library at configure
# time (FindJsonCpp.cmake).  We build the upstream release and install it into
# /usr/local so CMake can find it via find_package / pkg-config.
# ---------------------------------------------------------------------------
JSONCPP_VERSION=${JSONCPP_VERSION:-"1.9.6"}
JSONCPP_URL="https://github.com/open-source-parsers/jsoncpp.git"

echo "Building jsoncpp ${JSONCPP_VERSION} from source"
if [ -d "${CURRENT_DIR}/jsoncpp" ]; then
    echo "jsoncpp directory already exists, reusing."
    cd "${CURRENT_DIR}/jsoncpp"
    git checkout "$JSONCPP_VERSION"
else
    if ! git clone --branch "$JSONCPP_VERSION" --depth 1 "$JSONCPP_URL" "${CURRENT_DIR}/jsoncpp"; then
        echo "ERROR: Failed to clone jsoncpp ${JSONCPP_VERSION}"
        exit 1
    fi
    cd "${CURRENT_DIR}/jsoncpp"
fi

cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_SHARED_LIBS=ON \
    -DJSONCPP_WITH_TESTS=OFF \
    -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF
cmake --build build --parallel "$(nproc)"
cmake --install build

echo "jsoncpp installed: $(pkg-config --modversion jsoncpp)"

cd "${CURRENT_DIR}"

# ---------------------------------------------------------------------------
# MODE: rpms — install ROCm from a provided RPM repository
# ---------------------------------------------------------------------------
if [[ "$ROCM_INSTALL_MODE" == "rpms" ]]; then
    if [[ ! "$ROCM_REPO_URL" =~ ^(https?|file):// ]]; then
        echo "ERROR: ROCM_REPO_URL does not look like a valid URL (got: ${ROCM_REPO_URL})"
        exit 1
    fi
    echo "Installing ROCm from ${ROCM_REPO_URL}"

    ROCM_GPG_URL="https://public.dhe.ibm.com/software/server/POWER/Linux/AMD/RPM-GPG-KEY-PAMD"
    ROCM_GPG_PATH="/etc/pki/rpm-gpg/RPM-GPG-KEY-PAMD"
    echo "Importing ROCm GPG key from ${ROCM_GPG_URL}"
    wget -q -O "${ROCM_GPG_PATH}" "${ROCM_GPG_URL}"
    rpm --import "${ROCM_GPG_PATH}"

    cat > /etc/yum.repos.d/rocm.repo <<EOF
[ROCm]
name=ROCm
baseurl=${ROCM_REPO_URL}
enabled=1
gpgcheck=1
gpgkey=file://${ROCM_GPG_PATH}
EOF
    dnf install -y rocm-complete
    ROCM_PATH=/opt/rocm
fi

# Set ROCm path
export ROCM_PATH
export PATH=$ROCM_PATH/bin:$PATH
export LD_LIBRARY_PATH="${ROCM_PATH}/lib:${ROCM_PATH}/lib64:${LD_LIBRARY_PATH:-}"

# ROCm bundles its own copies of system libraries (lzma, drm, elfutils, …) under
# lib/rocm_sysdeps/lib.  In containers (e.g. UBI) these OS packages are absent,
# so we must make the sysdeps directory visible to both the runtime linker and the
# link-time linker, and point pkg-config at the bundled .pc files.
ROCM_SYSDEPS_LIB="${ROCM_PATH}/lib/rocm_sysdeps/lib"
if [[ -d "$ROCM_SYSDEPS_LIB" ]]; then
    export LD_LIBRARY_PATH="${ROCM_SYSDEPS_LIB}:${LD_LIBRARY_PATH}"
    export LDFLAGS="-Wl,-rpath,${ROCM_SYSDEPS_LIB} ${LDFLAGS:-}"
    export PKG_CONFIG_PATH="${ROCM_SYSDEPS_LIB}/pkgconfig:${PKG_CONFIG_PATH:-}"
fi

if ! command -v hipcc &>/dev/null; then
    echo "ERROR: hipcc not found under ROCM_PATH=${ROCM_PATH}. Check your ROCm installation."
    exit 1
fi
echo "ROCm hipcc: $(hipcc --version | head -1)"

# ---------------------------------------------------------------------------
# Clone Mooncake
# ---------------------------------------------------------------------------
echo "Cloning Mooncake ${PACKAGE_VERSION}"
if [ -d "${CURRENT_DIR}/Mooncake/.git" ]; then
    echo "Mooncake directory already exists, reusing."
    cd "${CURRENT_DIR}/Mooncake"
    git fetch --tags origin
    git checkout "$PACKAGE_VERSION"
else
    if ! git clone --branch "$PACKAGE_VERSION" --depth 1 "$PACKAGE_URL" "${CURRENT_DIR}/Mooncake"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
    fi
    cd "${CURRENT_DIR}/Mooncake"
fi

git submodule sync
git submodule update --init --recursive

echo "Current Mooncake commit:"
git --no-pager log -1 --oneline

# ---------------------------------------------------------------------------
# Install Python build dependencies
# ---------------------------------------------------------------------------
$PYTHON -m pip install --upgrade pip
# Use --ignore-installed to avoid conflicts with RPM-managed packages
# (e.g. setuptools installed by the system python3.12 RPM has no RECORD file
# and pip cannot uninstall it — ignore-installed overlays our versions on top).
$PYTHON -m pip install --upgrade --ignore-installed \
    "scikit-build-core>=1.0" \
    "pybind11>=2.13" \
    "numpy>=1.24" \
    "setuptools>=61" \
    wheel

# ---------------------------------------------------------------------------
# Build mooncake-transfer-engine wheel with ROCm/HIP support
#
# scikit-build-core is the build backend (pyproject.toml).  CMake options are
# passed via SKBUILD_CMAKE_ARGS.  We enable USE_HIP and point CMake at the
# ROCm HIP CMake config, then disable every Go/SPDK/optional component that
# is not needed for the wheel and not available on ppc64le UBI 10.
#
# USE_CUDA is explicitly disabled (default OFF in pyproject.toml but set here
# for clarity) so cmake does not auto-enable it when USE_HIP is found.
# WITH_STORE=OFF disables the mooncake-store C++ library, which requires Boost
# headers (boost/functional/hash.hpp, boost/uuid/uuid.hpp) that are not
# available in RHEL 10.  The transfer engine itself does not need the store.
# WITH_STORE_RUST=OFF must accompany WITH_STORE=OFF (CMake enforces this).
# WITH_STORE_GO / WITH_P2P_STORE are also disabled for completeness.
# ---------------------------------------------------------------------------

export CMAKE_PREFIX_PATH="${ROCM_PATH}/lib/cmake:${ROCM_PATH}:${CMAKE_PREFIX_PATH:-}"

SKBUILD_CMAKE_ARGS="-DUSE_HIP=ON"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DUSE_CUDA=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DWITH_STORE=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DWITH_STORE_RUST=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DWITH_STORE_GO=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DWITH_P2P_STORE=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DWITH_EP=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DBUILD_BENCHMARK=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DBUILD_UNIT_TESTS=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DBUILD_EXAMPLES=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DUSE_ETCD=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DSTORE_USE_ETCD=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DSTORE_USE_K8S_LEASE=OFF"
SKBUILD_CMAKE_ARGS="${SKBUILD_CMAKE_ARGS};-DCMAKE_BUILD_TYPE=Release"
export SKBUILD_CMAKE_ARGS

echo "Building mooncake-transfer-engine-rocm wheel (this will take a while)"
if ! MAX_JOBS=$(nproc) $PYTHON -m pip wheel . \
        --no-build-isolation \
        --no-deps \
        -w "${CURRENT_DIR}/dist"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "Built mooncake wheel(s):"
ls -lh "${CURRENT_DIR}/dist"/mooncake*.whl

# ---------------------------------------------------------------------------
# Install the wheel and its runtime dependencies
# ---------------------------------------------------------------------------
$PYTHON -m pip install \
    --prefer-binary \
    --extra-index-url "${DEVPI_INDEX}" \
    aiohttp msgpack requests

$PYTHON -m pip install "${CURRENT_DIR}/dist"/mooncake*.whl

# ---------------------------------------------------------------------------
# Import test
# ---------------------------------------------------------------------------
echo "Running import test"
cd "${CURRENT_DIR}"

if ! $PYTHON -c "import mooncake; print('mooncake version:', mooncake.__version__)"; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
