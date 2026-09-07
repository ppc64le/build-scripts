#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : torchvision-rocm
# Version       : v0.28.0
# Source repo   : https://github.com/pytorch/vision.git
# Tested on     : UBI:10 (ppc64le)
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ameil Kumar <ameil.kumar@ibm.com>
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
# PyTorch is built from source before torchvision so that the ROCm-enabled
# torch shared libraries are available at torchvision's CMake configure time.
#
# Usage:
#   ./torchvision_0.28.0_rocm_ubi_10.sh [v0.28.0]
#
# Environment variables honoured (can be set before running):
#   PACKAGE_VERSION      - torchvision tag to build (default: v0.28.0)
#   PYTORCH_VERSION      - PyTorch tag to build and install (default: v2.13.0)
#   ROCM_INSTALL_MODE    - rpms (default) or path
#   ROCM_PATH            - Path to ROCm installation (default: /opt/rocm)
#   ROCM_REPO_URL        - RPM repo baseurl for ROCm
#   PYTORCH_ROCM_ARCH    - Semicolon-separated GPU targets
#                          (default: "gfx90a;gfx950")
#   PYTORCH_PATCH_BASE   - Base URL for PyTorch patches
#
# ---------------------------------------------------------------------------

set -e

PACKAGE_NAME=torchvision
PACKAGE_VERSION=${1:-v0.28.0}
PACKAGE_URL=https://github.com/pytorch/vision.git
CURRENT_DIR=$(pwd)

PYTORCH_VERSION=${PYTORCH_VERSION:-v2.13.0}
PYTORCH_URL=https://github.com/pytorch/pytorch.git

ROCM_INSTALL_MODE=${ROCM_INSTALL_MODE:-"rpms"}   # rpms | path
ROCM_REPO_URL=${ROCM_REPO_URL:-"https://public.dhe.ibm.com/software/server/POWER/Linux/AMD/ROCm/RHEL/10/ppc64le"}
ROCM_PATH=${ROCM_PATH:-/opt/rocm}

# GPU architecture targets — override via env var
PYTORCH_ROCM_ARCH=${PYTORCH_ROCM_ARCH:-"gfx90a;gfx950"}

if [[ "$ROCM_INSTALL_MODE" != "rpms" && "$ROCM_INSTALL_MODE" != "path" ]]; then
    echo "ERROR: ROCM_INSTALL_MODE must be one of: rpms, path"
    exit 1
fi

echo "=== TorchVision ROCm Build (torch from source) ==="
echo "  PACKAGE_VERSION    : $PACKAGE_VERSION"
echo "  PYTORCH_VERSION    : $PYTORCH_VERSION"
echo "  ROCM_INSTALL_MODE  : $ROCM_INSTALL_MODE"
echo "  ROCM_PATH          : $ROCM_PATH"
echo "  PYTORCH_ROCM_ARCH  : $PYTORCH_ROCM_ARCH"
echo "==================================================="

# ---------------------------------------------------------------------------
# Install system build dependencies
# ---------------------------------------------------------------------------

# Python packages must appear first (wrapper script requirement).
yum install -y python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    git make wget patch cmake ninja-build \
    openblas openblas-devel \
    libjpeg-devel libpng-devel

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

# Use Python 3.12 for the build so the produced wheels are cp312
PYTHON=python3.12

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
    yum install -y rocm-complete
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
# Build PyTorch from source (ROCm)
# ---------------------------------------------------------------------------

# Use OpenBLAS instead of MKL (MKL does not support Power).
# Disable CUDA/Intel tooling so cmake does not search for them.
export PYTORCH_ROCM_ARCH
export BLAS=OpenBLAS
export USE_CUDA=0
export USE_XPU=0
export USE_ROCM=1

export CMAKE_PREFIX_PATH="${ROCM_PATH}:${CMAKE_PREFIX_PATH:-}"

echo "Cloning PyTorch ${PYTORCH_VERSION}"
if [ -d "${CURRENT_DIR}/pytorch" ]; then
    echo "pytorch directory already exists, reusing."
    cd "${CURRENT_DIR}/pytorch"
    git checkout "$PYTORCH_VERSION"
else
    if ! git clone --recursive --branch "$PYTORCH_VERSION" "$PYTORCH_URL" "${CURRENT_DIR}/pytorch"; then
        echo "------------------pytorch:clone_fails---------------------------------------"
        echo "$PYTORCH_URL pytorch"
        echo "pytorch  |  $PYTORCH_URL | $PYTORCH_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
    fi
    cd "${CURRENT_DIR}/pytorch"
fi

git submodule sync
git submodule update --init --recursive

# Install PyTorch build dependencies
$PYTHON -m pip install --upgrade pip
$PYTHON -m pip install --group dev || $PYTHON -m pip install -r requirements.txt

# Run ROCm source transformation
echo "Running ROCm hipify transformation"
$PYTHON tools/amd_build/build_amd.py

# Apply patches
# Fix CUDAGuard narrowing conversion errors under GCC 14 in ROCm HIP flash-attn files
# This patch is required — fail loudly if it cannot be applied
wget https://raw.githubusercontent.com/ppc64le/build-scripts/9c57d3b2c54a629d3cf6f45095b394f85374da3f/p/pytorch-rocm/pytorch_v2.13.0_rocm_cuda_guard_narrowing.patch
git apply pytorch_v2.13.0_rocm_cuda_guard_narrowing.patch

# Fix FastGeluAsm explicit specializations rejected by AMD clang 23.0 in composable_kernel
# This patch is required — fail loudly if it cannot be applied
wget https://raw.githubusercontent.com/ppc64le/build-scripts/9c57d3b2c54a629d3cf6f45095b394f85374da3f/p/pytorch-rocm/pytorch_v2.13.0_rocm_fastgeluasm.patch
git apply --directory=third_party/composable_kernel pytorch_v2.13.0_rocm_fastgeluasm.patch

# Build
echo "Building PyTorch ${PYTORCH_VERSION} (this will take a while)"
export PYTORCH_BUILD_VERSION=${PYTORCH_VERSION#v}+rocm7.14
export PYTORCH_BUILD_NUMBER=1

# Rename the pip distribution to "torch-rocm" for ROCm stack isolation on devpi.
# The import name (torch) is unchanged — only the wheel distribution name changes.
#
# WHY sed on pyproject.toml:
#   PyTorch v2.13.0 has a pyproject.toml with [project] name = "torch".
#   setuptools>=77 (which this build requires) reads pyproject.toml as the
#   authoritative metadata source — it takes precedence over setup.py's
#   setup(name=...) call.  TORCH_PACKAGE_NAME env var only affects setup.py
#   but never reaches the wheel name because setuptools overwrites it from
#   pyproject.toml.  The only reliable fix is to patch the name in-place
#   before the build runs, exactly as torchaudio-rocm patches setup.py.
sed -i 's/^name = "torch"$/name = "torch-rocm"/' pyproject.toml
echo "Patched pyproject.toml: name = torch-rocm"

# Build wheel via setup.py directly.
# pip wheel always invokes PEP 517 (even with --no-build-isolation), which
# spawns a subprocess that does not inherit the current environment — causing
# cmake to re-configure without PYTORCH_ROCM_ARCH and fail.
# setup.py bdist_wheel runs in-process: all exported env vars are visible,
# cmake skips recompilation because build/ already exists and targets are
# up to date, and setuptools reads the patched pyproject.toml for the name.
echo "Building distribution wheel"
if ! MAX_JOBS=$(nproc) $PYTHON setup.py bdist_wheel --dist-dir "${CURRENT_DIR}/dist"; then
    echo "------------------pytorch:Install_fails-------------------------------------"
    echo "$PYTORCH_URL pytorch"
    echo "pytorch  |  $PYTORCH_URL | $PYTORCH_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Install from the renamed wheel so pip registers it as torch-rocm
$PYTHON -m pip install --no-build-isolation "${CURRENT_DIR}/dist"/torch_rocm-*.whl

# Verify torch is importable and ROCm is visible through it
echo "Verifying torch install"
cd "${CURRENT_DIR}"
export ROCPROFILER_LOG_LEVEL=0
$PYTHON -c "import torch; print('torch version :', torch.__version__); print('ROCm available:', torch.cuda.is_available())"

# ---------------------------------------------------------------------------
# Clone torchvision
# ---------------------------------------------------------------------------
echo "Cloning torchvision ${PACKAGE_VERSION}"
if [ -d "${CURRENT_DIR}/vision" ]; then
    echo "vision directory already exists, reusing."
    cd "${CURRENT_DIR}/vision"
    git checkout "$PACKAGE_VERSION"
else
    if ! git clone --branch "$PACKAGE_VERSION" "$PACKAGE_URL" "${CURRENT_DIR}/vision"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
    fi
    cd "${CURRENT_DIR}/vision"
fi

# ---------------------------------------------------------------------------
# Apply patches
# ---------------------------------------------------------------------------
PATCH_BASE_URL=${PATCH_BASE_URL:-"https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/torchvision"}

# License exclusion patch — required; removes SWAG CC-BY-NC-4.0 licensed
# models (regnet.py, vision_transformer SWAG weights) from the wheel.
LICENSE_PATCH_FILE="0001-Exclude-source-that-has-commercial-license_v0.28.0.patch"
wget -q -O "${CURRENT_DIR}/${LICENSE_PATCH_FILE}" "${PATCH_BASE_URL}/${LICENSE_PATCH_FILE}"
git apply "${CURRENT_DIR}/${LICENSE_PATCH_FILE}"

# Patch out the git-sha injection in setup.py that breaks reproducible builds
sed -i '/elif sha != "Unknown":/,+1d' setup.py

# Rename the distribution to "torchvision-rocm" via the env var that
# torchvision's setup.py already supports (TORCHVISION_PACKAGE_NAME).
# The import name (torchvision) is unchanged — only the pip distribution name
# changes.
export TORCHVISION_PACKAGE_NAME="torchvision-rocm"

# Tell torchvision's get_requirements() to list "torch-rocm" as its torch
# dependency instead of "torch". torchvision's setup.py reads TORCH_PACKAGE_NAME
# at install_requires time. Without this, pip fails to install the wheel because
# it looks for "torch" which doesn't exist — only "torch-rocm" is installed.
export TORCH_PACKAGE_NAME="torch-rocm"

# ---------------------------------------------------------------------------
# Build torchvision-rocm wheel
# ---------------------------------------------------------------------------
echo "Building torchvision-rocm wheel"

# Let torchvision's CMake find the installed torch (editable install above)
export TORCH_CMAKE_PREFIX=$($PYTHON -c 'import torch; print(torch.utils.cmake_prefix_path)')
export CMAKE_PREFIX_PATH="${TORCH_CMAKE_PREFIX}:${ROCM_PATH}:${CMAKE_PREFIX_PATH:-}"

export BUILD_VERSION="${PACKAGE_VERSION#v}"
export SETUPTOOLS_SCM_PRETEND_VERSION="${BUILD_VERSION}"

if ! MAX_JOBS=$(nproc) $PYTHON setup.py bdist_wheel --dist-dir "${CURRENT_DIR}"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Install the wheel we just built so the import test can run.
# torch-rocm is already installed (editable); pass --find-links so pip can
# satisfy that dependency without hitting PyPI for it.
ROCM_WHL=$(ls "${CURRENT_DIR}"/torchvision_rocm-${BUILD_VERSION}-*.whl)
echo "Built wheel: $(basename $ROCM_WHL)"
$PYTHON -m pip install --find-links "${CURRENT_DIR}" "$ROCM_WHL"

# ---------------------------------------------------------------------------
# Import test
# ---------------------------------------------------------------------------
echo "Running import test"
cd "${CURRENT_DIR}"


if ! $PYTHON -c "import torch; import torchvision; print('torch version     :', torch.__version__); print('torchvision version:', torchvision.__version__); print('ROCm available    :', torch.cuda.is_available())"; then
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