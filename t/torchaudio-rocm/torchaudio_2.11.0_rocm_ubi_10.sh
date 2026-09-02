#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : torchaudio
# Version       : v2.11.0
# Source repo   : https://github.com/pytorch/audio.git
# Tested on     : UBI:10 (ppc64le)
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2.0
# Maintainer    : Ameil Kumar <ameil.kumar@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#
# ROCm installation mode (ROCM_INSTALL_MODE env var):
#   rpms   (default) - Install ROCm RPMs from a provided repo URL
#   path             - Assume ROCm is already present; use ROCM_PATH as-is
#
# PyTorch is built from source before torchaudio so that the ROCm-enabled
# torch shared libraries are available at torchaudio's CMake configure time.
#
# Usage:
#   ./torchaudio_2.11.0_rocm_ubi_10.sh [--rocm-install-mode rpms|path]
#                                       [--version v2.11.0]
#
# Environment variables honoured (can be set before running):
#   PACKAGE_VERSION      - torchaudio tag to build (default: v2.11.0)
#   PYTORCH_VERSION      - PyTorch tag to build and install (default: v2.13.0)
#   ROCM_PATH            - Path to ROCm installation (default: /opt/rocm)
#   ROCM_REPO_URL        - RPM repo baseurl for ROCm
#   PYTORCH_ROCM_ARCH    - Semicolon-separated GPU targets
#                          (default: "gfx90a;gfx950")
#   PYTORCH_PATCH_BASE   - Base URL for PyTorch patches
#
# ---------------------------------------------------------------------------

set -e

PACKAGE_NAME=audio
PACKAGE_URL=https://github.com/pytorch/audio.git
PACKAGE_VERSION=${PACKAGE_VERSION:-v2.11.0}
SCRIPT_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

PYTORCH_VERSION=${PYTORCH_VERSION:-v2.13.0}
PYTORCH_URL=https://github.com/pytorch/pytorch.git

ROCM_INSTALL_MODE=${ROCM_INSTALL_MODE:-"rpms"}   # rpms | path
ROCM_REPO_URL=${ROCM_REPO_URL:-"https://public.dhe.ibm.com/software/server/POWER/Linux/AMD/ROCm/RHEL/10/ppc64le"}
ROCM_PATH=${ROCM_PATH:-/opt/rocm}

# GPU architecture targets — override via env var
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
        --version)
            PACKAGE_VERSION="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--rocm-install-mode rpms|path] [--version v2.11.0]"
            exit 1
            ;;
    esac
done

if [[ "$ROCM_INSTALL_MODE" != "rpms" && "$ROCM_INSTALL_MODE" != "path" ]]; then
    echo "ERROR: --rocm-install-mode must be one of: rpms, path"
    exit 1
fi

echo "=== TorchAudio ROCm Build (torch from source) ==="
echo "  PACKAGE_VERSION    : $PACKAGE_VERSION"
echo "  PYTORCH_VERSION    : $PYTORCH_VERSION"
echo "  ROCM_INSTALL_MODE  : $ROCM_INSTALL_MODE"
echo "  ROCM_PATH          : $ROCM_PATH"
echo "  PYTORCH_ROCM_ARCH  : $PYTORCH_ROCM_ARCH"
echo "=================================================="

# ---------------------------------------------------------------------------
# Install system build dependencies
# ---------------------------------------------------------------------------

# Python packages must appear first (wrapper script requirement).
yum install -y python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    git make wget patch cmake ninja-build \
    openblas openblas-devel

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
if [ -d "${SCRIPT_DIR}/pytorch" ]; then
    echo "pytorch directory already exists, reusing."
    cd "${SCRIPT_DIR}/pytorch"
    git checkout "$PYTORCH_VERSION"
else
    if ! git clone --recursive --branch "$PYTORCH_VERSION" "$PYTORCH_URL" "${SCRIPT_DIR}/pytorch"; then
        echo "------------------pytorch:clone_fails---------------------------------------"
        echo "$PYTORCH_URL pytorch"
        echo "pytorch  |  $PYTORCH_URL | $PYTORCH_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
    fi
    cd "${SCRIPT_DIR}/pytorch"
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
if ! MAX_JOBS=$(nproc) $PYTHON setup.py bdist_wheel --dist-dir "${SCRIPT_DIR}/dist"; then
    echo "------------------pytorch:Install_fails-------------------------------------"
    echo "$PYTORCH_URL pytorch"
    echo "pytorch  |  $PYTORCH_URL | $PYTORCH_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Install from the renamed wheel so pip registers it as torch-rocm
$PYTHON -m pip install --no-build-isolation "${SCRIPT_DIR}/dist"/torch_rocm-*.whl

# Verify torch is importable and ROCm is visible through it
echo "Verifying torch install"
cd "${SCRIPT_DIR}"
export ROCPROFILER_LOG_LEVEL=0
$PYTHON -c "import torch; print('torch version :', torch.__version__); print('ROCm available:', torch.cuda.is_available())"

# ---------------------------------------------------------------------------
# Clone torchaudio
# ---------------------------------------------------------------------------
echo "Cloning torchaudio ${PACKAGE_VERSION}"
if [ -d "${SCRIPT_DIR}/audio" ]; then
    echo "audio directory already exists, reusing."
    cd "${SCRIPT_DIR}/audio"
    git checkout "$PACKAGE_VERSION"
else
    if ! git clone --branch "$PACKAGE_VERSION" "$PACKAGE_URL" "${SCRIPT_DIR}/audio"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
        exit 1
    fi
    cd "${SCRIPT_DIR}/audio"
fi

# ---------------------------------------------------------------------------
# Apply patches
# ---------------------------------------------------------------------------
PATCH_BASE_URL=${PATCH_BASE_URL:-"https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/torchaudio"}

# License exclusion patch — required; removes commercially licensed source files
LICENSE_PATCH_FILE="0001-Excluded-source-that-has-commercial-license-new.patch"
wget -q -O "${SCRIPT_DIR}/${LICENSE_PATCH_FILE}" "${PATCH_BASE_URL}/${LICENSE_PATCH_FILE}"
git apply "${SCRIPT_DIR}/${LICENSE_PATCH_FILE}"
echo "Applied license exclusion patch"

# ---------------------------------------------------------------------------
# Build torchaudio-rocm wheel
# ---------------------------------------------------------------------------
echo "Building torchaudio-rocm wheel"

# Rename distribution to torchaudio-rocm for ROCm stack isolation.
# torchaudio's setup.py hardcodes name="torchaudio" with no env var override,
# so we patch it directly. The import name (torchaudio) is unchanged.
sed -i 's/name="torchaudio"/name="torchaudio-rocm"/' setup.py

export BUILD_VERSION="${PACKAGE_VERSION#v}"
export SETUPTOOLS_SCM_PRETEND_VERSION="${BUILD_VERSION}"

# Let torchaudio's CMake find the installed torch
export TORCH_CMAKE_PREFIX=$($PYTHON -c 'import torch; print(torch.utils.cmake_prefix_path)')
export CMAKE_PREFIX_PATH="${TORCH_CMAKE_PREFIX}:${ROCM_PATH}:${CMAKE_PREFIX_PATH:-}"

# Disable optional media deps — not needed for the ROCm wheel
export USE_FFMPEG=OFF
export BUILD_SOX=OFF
export USE_OPENMP=OFF
export BUILD_TORCHAUDIO_PYTHON_EXTENSION=ON

$PYTHON -m pip install --upgrade setuptools wheel

# Build the wheel and install it in one step. pip wheel saves the .whl to
# $SCRIPT_DIR; pip install then installs it for the import test.
if ! $PYTHON -m pip wheel . --no-build-isolation --no-deps -w "${SCRIPT_DIR}"; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

ROCM_WHL=$(ls "${SCRIPT_DIR}"/torchaudio_rocm-${BUILD_VERSION}-*.whl)
echo "Built wheel: $(basename $ROCM_WHL)"
$PYTHON -m pip install "$ROCM_WHL"

# ---------------------------------------------------------------------------
# Import test
# ---------------------------------------------------------------------------
echo "Running import test"
cd "${SCRIPT_DIR}"

if ! $PYTHON -c "import torch; import torch._C; import torchaudio; print('torchaudio version:', torchaudio.__version__)"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_Import_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Import_Success"
exit 0