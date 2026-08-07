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
#   rpms   (default) - Install ROCm RPMs from repo URL
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
#   ROCM_REPO_URL        - RPM repo baseurl (default: internal placeholder for 7.14.0,
#                          UPDATE THIS before use)
#   PACKAGE_VERSION      - PyTorch tag to build (default: v2.13.0)
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
# TODO: Replace this placeholder with the real internal ROCm 7.14.0 repo URL before use
ROCM_REPO_URL=${ROCM_REPO_URL:-"http://PLACEHOLDER/rocm/7.14.0/rhel9/main"}
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
echo "Installing system dependencies"
dnf install -y git make wget patch cmake ninja-build \
    python3 python3-devel python3-pip \
    gcc gcc-c++ \
    openblas openblas-devel
echo "Installed required deps from RH"

# ---------------------------------------------------------------------------
# MODE: rpms — install ROCm from a provided RPM repository
# ---------------------------------------------------------------------------
if [[ "$ROCM_INSTALL_MODE" == "rpms" ]]; then
    if [[ ! "$ROCM_REPO_URL" =~ ^https?:// ]]; then
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
    # TODO: Update with published ROCm RPMs when available
    dnf install -y rocm-dev hipcc hipblas hipsparse rocblas rocsparse \
        rocfft rocrand rccl miopen-hip rocm-cmake
    ROCM_PATH=/opt/rocm
fi

# Set ROCm path
export ROCM_PATH
export PATH=$ROCM_PATH/bin:$PATH
export LD_LIBRARY_PATH="${ROCM_PATH}/lib:${ROCM_PATH}/lib64:${ROCM_PATH}/lib/rocm_sysdeps/lib:${LD_LIBRARY_PATH:-}"
# ROCm ships its own libdrm.pc (via hsa-rocr's rocm_sysdeps bundle). Append it so
# that rocm_smi-config.cmake's pkg_check_modules(REQUIRED libdrm) succeeds even in
# containers where libdrm-devel is not installed.
export PKG_CONFIG_PATH="${ROCM_PATH}/lib/rocm_sysdeps/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
# libaotriton_v2.so and librocm_sysdeps_dw.so.1 both need librocm_sysdeps_liblzma.so.5
# which lives in rocm_sysdeps/lib but is not on the default linker search path.
# -L tells ld where to find it at link time; -rpath bakes the path into every linked binary.
export LDFLAGS="-L${ROCM_PATH}/lib/rocm_sysdeps/lib -Wl,-rpath,${ROCM_PATH}/lib/rocm_sysdeps/lib ${LDFLAGS:-}"

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
pip3 install --upgrade pip
pip3 install --group dev || pip3 install -r requirements.txt

# Run ROCm source transformation
echo "Running ROCm hipify transformation"
python3 tools/amd_build/build_amd.py

# Apply patches
# For each patch: use a local copy if already present in SCRIPT_DIR (e.g. bind-mounted
# or pre-staged), otherwise fetch from upstream.
echo "Applying patches"
PATCH_BASE_URL="https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pytorch"

apply_patch() {
    local patch_file="$1"
    local git_apply_args="${2:-}"   # optional extra args, e.g. --directory=...
    if [ -f "${SCRIPT_DIR}/${patch_file}" ]; then
        echo "Using local ${patch_file}"
        cp "${SCRIPT_DIR}/${patch_file}" "${patch_file}"
    else
        echo "Fetching ${patch_file} from upstream"
        wget -q "${PATCH_BASE_URL}/${patch_file}"
    fi
    # shellcheck disable=SC2086
    git apply ${git_apply_args} "${patch_file}" \
        || echo "${patch_file} failed to apply or already applied, skipped"
}

# Fix CUDAGuard narrowing conversion errors in ROCm HIP flash-attn files
apply_patch "pytorch_v2.13.0_rocm_cuda_guard_narrowing.patch"

# Fix FastGeluAsm explicit specializations rejected by AMD clang 23.0 in composable_kernel
apply_patch "pytorch_v2.13.0_rocm_fastgeluasm.patch" "--directory=third_party/composable_kernel"

# Build
echo "Building PyTorch (this will take a while)"
export PYTORCH_BUILD_VERSION=${PACKAGE_VERSION#v}
export PYTORCH_BUILD_NUMBER=1

if ! MAX_JOBS=$(nproc) python3 -m pip install --no-build-isolation -v -e .; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Build Wheels
echo "Building distribution wheel"
python3 -m pip wheel --no-build-isolation -v -w dist .

# Basic import test
echo "Running basic import test"
cd "${SCRIPT_DIR}"

if ! python3 -c "import torch; print('torch version :', torch.__version__); print('ROCm available:', torch.cuda.is_available())"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_Import_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Import_Success"
exit 0
