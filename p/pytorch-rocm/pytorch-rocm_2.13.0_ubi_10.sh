#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : torch
# Version       : v2.13.0
# Source repo   : https://github.com/pytorch/pytorch.git
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
# The pip distribution name is kept as the standard upstream name "torch".
# The local version suffix (+rocm7.14) and the platform tag (linux_ppc64le)
# in the wheel filename uniquely identify this as a ROCm ppc64le build on
# the devpi index. Using the standard name means pip dependency resolution
# works correctly for all downstream packages (torchvision, vllm, etc.)
# without any workarounds.
#
# Usage:
#   ./torch_rocm_v2.13.0_ubi10_stdnames.sh [v2.13.0]
#
# Environment variables honoured (can be set before running):
#   PACKAGE_VERSION   - PyTorch tag to build (default: v2.13.0)
#   ROCM_INSTALL_MODE - rpms (default) or path
#   ROCM_PATH         - Path to ROCm installation (default: /opt/rocm)
#   ROCM_REPO_URL     - RPM repo baseurl for ROCm
#   PYTORCH_ROCM_ARCH - Semicolon-separated GPU targets (default: "gfx90a;gfx950")
#
# ---------------------------------------------------------------------------

set -e

PACKAGE_NAME=torch
PACKAGE_VERSION=${1:-v2.13.0}
PACKAGE_URL=https://github.com/pytorch/pytorch.git
CURRENT_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

ROCM_INSTALL_MODE=${ROCM_INSTALL_MODE:-"rpms"}
ROCM_REPO_URL=${ROCM_REPO_URL:-"https://public.dhe.ibm.com/software/server/POWER/Linux/AMD/ROCm/RHEL/10/ppc64le"}
ROCM_PATH=${ROCM_PATH:-/opt/rocm}

PYTORCH_ROCM_ARCH=${PYTORCH_ROCM_ARCH:-"gfx90a;gfx950"}

if [[ "$ROCM_INSTALL_MODE" != "rpms" && "$ROCM_INSTALL_MODE" != "path" ]]; then
    echo "ERROR: ROCM_INSTALL_MODE must be one of: rpms, path"
    exit 1
fi

echo "=== PyTorch ROCm Build ==="
echo "  PACKAGE_VERSION   : $PACKAGE_VERSION"
echo "  ROCM_INSTALL_MODE : $ROCM_INSTALL_MODE"
echo "  ROCM_PATH         : $ROCM_PATH"
echo "  PYTORCH_ROCM_ARCH : $PYTORCH_ROCM_ARCH"
echo "=========================="

# ---------------------------------------------------------------------------
# Install system build dependencies
# ---------------------------------------------------------------------------
yum install -y \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    git make wget patch cmake ninja-build \
    openblas openblas-devel \
    zlib-devel curl \
    meson pkgconf-pkg-config

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

PYTHON=python

# ---------------------------------------------------------------------------
# Build libdrm from source (not available in UBI 10 repo)
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

export PKG_CONFIG_PATH="/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="/usr/local/lib64:/usr/local/lib:${LD_LIBRARY_PATH:-}"
echo "libdrm installed: $(pkg-config --modversion libdrm)"
cd "${CURRENT_DIR}"

# ---------------------------------------------------------------------------
# Install ROCm
# ---------------------------------------------------------------------------
if [[ "$ROCM_INSTALL_MODE" == "rpms" ]]; then
    if [[ ! "$ROCM_REPO_URL" =~ ^(https?|file):// ]]; then
        echo "ERROR: ROCM_REPO_URL does not look like a valid URL (got: ${ROCM_REPO_URL})"
        exit 1
    fi
    echo "Installing ROCm from ${ROCM_REPO_URL}"
    cat > /etc/yum.repos.d/rocm.repo <<EOF
[ROCm]
name=ROCm
baseurl=${ROCM_REPO_URL}
enabled=1
gpgcheck=0
EOF
    yum install -y rocm-complete
    ROCM_PATH=/opt/rocm
fi

export ROCM_PATH
export PATH=$ROCM_PATH/bin:$PATH
export LD_LIBRARY_PATH="${ROCM_PATH}/lib:${ROCM_PATH}/lib64:${LD_LIBRARY_PATH:-}"

ROCM_SYSDEPS_LIB="${ROCM_PATH}/lib/rocm_sysdeps/lib"
if [[ -d "$ROCM_SYSDEPS_LIB" ]]; then
    export LD_LIBRARY_PATH="${ROCM_SYSDEPS_LIB}:${LD_LIBRARY_PATH}"
    export LDFLAGS="-Wl,-rpath,${ROCM_SYSDEPS_LIB} ${LDFLAGS:-}"
    export PKG_CONFIG_PATH="${ROCM_SYSDEPS_LIB}/pkgconfig:${PKG_CONFIG_PATH:-}"
fi

if ! command -v hipcc &>/dev/null; then
    echo "ERROR: hipcc not found under ROCM_PATH=${ROCM_PATH}."
    exit 1
fi
echo "ROCm hipcc: $(hipcc --version | head -1)"

# ---------------------------------------------------------------------------
# Build PyTorch from source (ROCm)
# ---------------------------------------------------------------------------
export PYTORCH_ROCM_ARCH
export BLAS=OpenBLAS
export USE_CUDA=0
export USE_XPU=0
export USE_ROCM=1
export CMAKE_PREFIX_PATH="${ROCM_PATH}:${CMAKE_PREFIX_PATH:-}"

echo "Cloning PyTorch ${PACKAGE_VERSION}"
if [ -d "${CURRENT_DIR}/pytorch" ]; then
    echo "pytorch directory already exists, reusing."
    cd "${CURRENT_DIR}/pytorch"
    git checkout "$PACKAGE_VERSION"
else
    if ! git clone --recursive --branch "$PACKAGE_VERSION" "$PACKAGE_URL" "${CURRENT_DIR}/pytorch"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
    fi
    cd "${CURRENT_DIR}/pytorch"
fi

git submodule sync
git submodule update --init --recursive

$PYTHON -m pip install --upgrade pip setuptools wheel
$PYTHON -m pip install --group dev || $PYTHON -m pip install -r requirements.txt

echo "Running ROCm hipify transformation"
$PYTHON tools/amd_build/build_amd.py

# Fix CUDAGuard narrowing conversion errors under GCC 14
wget https://raw.githubusercontent.com/ppc64le/build-scripts/9c57d3b2c54a629d3cf6f45095b394f85374da3f/p/pytorch-rocm/pytorch_v2.13.0_rocm_cuda_guard_narrowing.patch
git apply pytorch_v2.13.0_rocm_cuda_guard_narrowing.patch

# Fix FastGeluAsm explicit specializations rejected by AMD clang 23.0
wget https://raw.githubusercontent.com/ppc64le/build-scripts/9c57d3b2c54a629d3cf6f45095b394f85374da3f/p/pytorch-rocm/pytorch_v2.13.0_rocm_fastgeluasm.patch
git apply --directory=third_party/composable_kernel pytorch_v2.13.0_rocm_fastgeluasm.patch

echo "Building PyTorch ${PACKAGE_VERSION} (this will take a while)"
# Version suffix +rocm7.14 and platform tag linux_ppc64le in the wheel filename
# uniquely identify this as a ROCm ppc64le build on the devpi index.
export PYTORCH_BUILD_VERSION=${PACKAGE_VERSION#v}+rocm7.14
export PYTORCH_BUILD_NUMBER=1

if ! MAX_JOBS=$(nproc) $PYTHON setup.py bdist_wheel --dist-dir "${CURRENT_DIR}/dist"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

$PYTHON -m pip install --no-build-isolation "${CURRENT_DIR}/dist"/torch-*.whl

# Verify
echo "Verifying torch install"
cd "${CURRENT_DIR}"
export ROCPROFILER_LOG_LEVEL=0
$PYTHON -c "
import torch
print('torch version    :', torch.__version__)
print('torch.version.hip:', torch.version.hip)
print('ROCm available   :', torch.cuda.is_available())
if torch.version.hip is None:
    raise SystemExit('ERROR: torch.version.hip is None — ROCm build may have failed')
print('torch ROCm check passed')
"

echo "------------------$PACKAGE_NAME:Install_success-------------------------"
echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_Success"