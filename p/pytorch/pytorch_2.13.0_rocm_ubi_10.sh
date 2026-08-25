#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: pytorch
# Version	: v2.13.0
# Source repo	: https://github.com/pytorch/pytorch.git
# Tested on	: UBI:10 (ppc64le)
# Language	: Python
# Ci-Check	: True
# Script License: Apache License, Version 2 or later
# Maintainer	: Ameil Kumar <ameil.kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#
# ROCm installation mode (--rocm-install-mode):
#   rpms   (default) - Install ROCm RPMs from a provided repo URL
#   path             - Assume ROCm is already present; use ROCM_PATH as-is
#
# Usage:
#   ./pytorch_2.13.0_rocm_ubi_10.sh [--rocm-install-mode rpms|path]
#                                    [--rocm-arch "gfx90a;gfx950"]
#                                    [--version v2.13.0]
#
# Environment variables honoured (can be set before running):
#   ROCM_PATH            - Path to the ROCm installation (default: /opt/rocm)
#   PYTORCH_ROCM_ARCH    - Semicolon-separated GPU targets
#                          (default: "gfx90a;gfx950")
#   ROCM_REPO_URL        - RPM repo baseurl
#   PACKAGE_VERSION      - PyTorch tag to build (default: v2.13.0)
#
# The produced wheel distribution is named "torch-rocm" (pip install name)
# while the import name remains "torch".  This matches the naming convention
# used by torchvision-rocm and torchaudio-rocm in this repo, isolating the
# ROCm wheel from the standard CPU "torch" wheel on devpi.
# PyTorch's setup.py supports this via the TORCH_PACKAGE_NAME env var.
#
# ---------------------------------------------------------------------------

set -e

# Variables
PACKAGE_NAME=pytorch
PACKAGE_URL=https://github.com/pytorch/pytorch.git
PACKAGE_VERSION=${PACKAGE_VERSION:-v2.13.0}
SCRIPT_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

ROCM_INSTALL_MODE="rpms"   # rpms | path
ROCM_REPO_URL=${ROCM_REPO_URL:-"https://public.dhe.ibm.com/software/server/POWER/Linux/AMD/ROCm/RHEL/10/ppc64le"}
ROCM_PATH=${ROCM_PATH:-/opt/rocm}

# GPU architecture targets — override via env or --rocm-arch flag
PYTORCH_ROCM_ARCH=${PYTORCH_ROCM_ARCH:-"gfx90a;gfx950"}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --rocm-install-mode)
            ROCM_INSTALL_MODE="$2"
            shift 2
            ;;
        --rocm-arch)
            PYTORCH_ROCM_ARCH="$2"
            shift 2
            ;;
        --version)
            PACKAGE_VERSION="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--rocm-install-mode rpms|path] [--rocm-arch \"gfx90a;gfx950\"] [--version v2.13.0]"
            exit 1
            ;;
    esac
done

if [[ "$ROCM_INSTALL_MODE" != "rpms" && "$ROCM_INSTALL_MODE" != "path" ]]; then
    echo "ERROR: --rocm-install-mode must be one of: rpms, path"
    exit 1
fi

echo "=== PyTorch ROCm Build ==="
echo "  PACKAGE_VERSION      : $PACKAGE_VERSION"
echo "  ROCM_INSTALL_MODE    : $ROCM_INSTALL_MODE"
echo "  ROCM_PATH            : $ROCM_PATH"
echo "  PYTORCH_ROCM_ARCH    : $PYTORCH_ROCM_ARCH"
echo "=========================="

# ---------------------------------------------------------------------------
# Install system build dependencies
# ---------------------------------------------------------------------------
EPEL_URL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm"
if ! rpm -q epel-release &>/dev/null; then
    echo "Installing EPEL"
    dnf install -y "$EPEL_URL"
fi

echo "Installing system dependencies"
dnf install -y git make wget patch cmake ninja-build \
    python3.13 python3.13-devel python3.13-pip \
    gcc gcc-c++ \
    openblas openblas-devel
echo "Installed required deps from RH"

# Use Python 3.13 for the build so the produced wheel is cp313
PYTHON=python3.13

# ---------------------------------------------------------------------------
# MODE: rpms — install ROCm from a provided RPM repository
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

# Set ENV vars
# Use OpenBLAS instead of MKL (MKL does not support Power).
# Disable CUDA/Intel tooling so cmake does not search for them.
export PYTORCH_ROCM_ARCH
export BLAS=OpenBLAS
export USE_CUDA=0
export USE_XPU=0
export USE_ROCM=1

export CMAKE_PREFIX_PATH="${ROCM_PATH}:${CMAKE_PREFIX_PATH:-}"

# Clone PyTorch
echo "Cloning PyTorch ${PACKAGE_VERSION}"
if [ -d "${SCRIPT_DIR}/pytorch" ]; then
    echo "pytorch directory already exists, reusing."
    cd "${SCRIPT_DIR}/pytorch"
    git checkout "$PACKAGE_VERSION"
else
    if ! git clone --recursive --branch "$PACKAGE_VERSION" "$PACKAGE_URL" "${SCRIPT_DIR}/pytorch"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
        exit 1
    fi
    cd "${SCRIPT_DIR}/pytorch"
fi

git submodule sync
git submodule update --init --recursive

# Install build dependencies
$PYTHON -m pip install --upgrade pip
$PYTHON -m pip install --group dev || $PYTHON -m pip install -r requirements.txt

# Run ROCm source transformation
echo "Running ROCm hipify transformation"
$PYTHON tools/amd_build/build_amd.py

# Apply patches
echo "Applying patches"
PATCH_BASE_URL=${PATCH_BASE_URL:-"https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pytorch"}

# Fix CUDAGuard narrowing conversion errors under GCC 14 in ROCm HIP flash-attn files
# This patch is required — fail loudly if it cannot be downloaded or applied
wget -q -O "$SCRIPT_DIR/pytorch_v2.13.0_rocm_cuda_guard_narrowing.patch" "$PATCH_BASE_URL/pytorch_v2.13.0_rocm_cuda_guard_narrowing.patch"
git apply "$SCRIPT_DIR/pytorch_v2.13.0_rocm_cuda_guard_narrowing.patch"

# Fix FastGeluAsm explicit specializations rejected by AMD clang 23.0 in composable_kernel
# This patch is required — fail loudly if it cannot be downloaded or applied
wget -q -O "$SCRIPT_DIR/pytorch_v2.13.0_rocm_fastgeluasm.patch" "$PATCH_BASE_URL/pytorch_v2.13.0_rocm_fastgeluasm.patch"
git apply --directory=third_party/composable_kernel "$SCRIPT_DIR/pytorch_v2.13.0_rocm_fastgeluasm.patch"

# Build
echo "Building PyTorch (this will take a while)"
export PYTORCH_BUILD_VERSION=${PACKAGE_VERSION#v}+rocm
export PYTORCH_BUILD_NUMBER=1

# Rename the pip distribution to "torch-rocm" for ROCm stack isolation on devpi.
# The import name (torch) is unchanged — only the wheel distribution name changes.
# PyTorch's setup.py already supports this via TORCH_PACKAGE_NAME (line ~340).
export TORCH_PACKAGE_NAME="torch-rocm"

if ! MAX_JOBS=$(nproc) $PYTHON -m pip install --no-build-isolation -v -e .; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Build Wheels
echo "Building distribution wheel"
$PYTHON -m pip wheel --no-build-isolation -v -w dist .

# Basic import test
echo "Running basic import test"
cd "${SCRIPT_DIR}"

if ! $PYTHON -c "import torch; print('torch version :', torch.__version__); print('ROCm available:', torch.cuda.is_available())"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_Import_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Import_Success"
exit 0
