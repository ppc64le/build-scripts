#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : vision
# Version       : v0.28.0
# Source repo   : https://github.com/pytorch/vision.git
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
# ROCm torch wheel install mode (--torch-install-mode):
#   devpi  (default) - Install torch ROCm wheel from IBM devpi
#   local            - Install torch from a local .whl file (set TORCH_WHL_PATH)
#
# Usage:
#   ./torchvision_0.28.0_rocm_ubi_10.sh [--torch-install-mode devpi|local]
#                                        [--rocm-install-mode rpms|path]
#                                        [--version v0.28.0]
#
# Environment variables honoured (can be set before running):
#   PACKAGE_VERSION      - torchvision tag to build (default: v0.28.0)
#   ROCM_PATH            - Path to ROCm installation (default: /opt/rocm)
#   ROCM_REPO_URL        - RPM repo baseurl for ROCm
#   TORCH_WHL_PATH       - Path to local torch ROCm .whl (required when
#                          --torch-install-mode local)
#   TORCH_DEVPI_VERSION  - torch version specifier pulled from devpi
#                          (default: torch==2.13.0+rocm)
#
# ---------------------------------------------------------------------------

set -e

PACKAGE_NAME=vision
PACKAGE_URL=https://github.com/pytorch/vision.git
PACKAGE_VERSION=${PACKAGE_VERSION:-v0.28.0}
SCRIPT_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

ROCM_INSTALL_MODE="rpms"   # rpms | path
ROCM_REPO_URL=${ROCM_REPO_URL:-"https://public.dhe.ibm.com/software/server/POWER/Linux/AMD/ROCm/RHEL/10/ppc64le"}
ROCM_PATH=${ROCM_PATH:-/opt/rocm}

TORCH_INSTALL_MODE="devpi"  # devpi | local
TORCH_WHL_PATH=${TORCH_WHL_PATH:-""}

# TODO: replace specifier with the correct versioned devpi ROCm torch wheel
# once https://github.com/ppc64le/build-scripts/pull/XXXX is merged and
# the wheel is published to wheels.developerfirst.ibm.com.
TORCH_DEVPI_VERSION=${TORCH_DEVPI_VERSION:-"torch==2.13.0+rocm"}
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --torch-install-mode)
            TORCH_INSTALL_MODE="$2"
            shift 2
            ;;
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
            echo "Usage: $0 [--torch-install-mode devpi|local] [--rocm-install-mode rpms|path] [--version v0.28.0]"
            exit 1
            ;;
    esac
done

if [[ "$ROCM_INSTALL_MODE" != "rpms" && "$ROCM_INSTALL_MODE" != "path" ]]; then
    echo "ERROR: --rocm-install-mode must be one of: rpms, path"
    exit 1
fi

if [[ "$TORCH_INSTALL_MODE" != "devpi" && "$TORCH_INSTALL_MODE" != "local" ]]; then
    echo "ERROR: --torch-install-mode must be one of: devpi, local"
    exit 1
fi

if [[ "$TORCH_INSTALL_MODE" == "local" && -z "$TORCH_WHL_PATH" ]]; then
    echo "ERROR: --torch-install-mode local requires TORCH_WHL_PATH to be set"
    exit 1
fi

echo "=== TorchVision ROCm Build ==="
echo "  PACKAGE_VERSION    : $PACKAGE_VERSION"
echo "  ROCM_INSTALL_MODE  : $ROCM_INSTALL_MODE"
echo "  ROCM_PATH          : $ROCM_PATH"
echo "  TORCH_INSTALL_MODE : $TORCH_INSTALL_MODE"
echo "=============================="

# ---------------------------------------------------------------------------
# System dependencies
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
    libjpeg-devel libpng-devel freetype-devel openblas openblas-devel
echo "Installed required deps from RH"

PYTHON=python3.13

# ---------------------------------------------------------------------------
# ROCm install
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

export ROCM_PATH
export PATH=$ROCM_PATH/bin:$PATH
export LD_LIBRARY_PATH="${ROCM_PATH}/lib:${ROCM_PATH}/lib64:${LD_LIBRARY_PATH:-}"

ROCM_SYSDEPS_LIB="${ROCM_PATH}/lib/rocm_sysdeps/lib"
if [[ -d "$ROCM_SYSDEPS_LIB" ]]; then
    export LD_LIBRARY_PATH="${ROCM_SYSDEPS_LIB}:${LD_LIBRARY_PATH}"
    export LDFLAGS="-Wl,-rpath,${ROCM_SYSDEPS_LIB} ${LDFLAGS:-}"
fi

# ---------------------------------------------------------------------------
# Install torch ROCm wheel
# ---------------------------------------------------------------------------
$PYTHON -m pip install --upgrade pip

if [[ "$TORCH_INSTALL_MODE" == "local" ]]; then
    echo "Installing torch from local wheel: ${TORCH_WHL_PATH}"
    $PYTHON -m pip install "${TORCH_WHL_PATH}"
else
    echo "Installing torch from IBM devpi (${TORCH_DEVPI_VERSION})"
    # TODO: remove --pre once the ROCm torch wheel graduates to a stable devpi release
    $PYTHON -m pip install \
        --prefer-binary \
        --trusted-host wheels.developerfirst.ibm.com \
        --extra-index-url "${IBM_WHEELS}" \
        "${TORCH_DEVPI_VERSION}"
fi

# Verify torch is importable and ROCm is visible through it
echo "Verifying torch install"
$PYTHON -c "import torch; print('torch version:', torch.__version__); print('ROCm available:', torch.cuda.is_available())"

# ---------------------------------------------------------------------------
# Clone torchvision
# ---------------------------------------------------------------------------
echo "Cloning torchvision ${PACKAGE_VERSION}"
if [ -d "${SCRIPT_DIR}/vision" ]; then
    echo "vision directory already exists, reusing."
    cd "${SCRIPT_DIR}/vision"
    git checkout "$PACKAGE_VERSION"
else
    if ! git clone --branch "$PACKAGE_VERSION" "$PACKAGE_URL" "${SCRIPT_DIR}/vision"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
        exit 1
    fi
    cd "${SCRIPT_DIR}/vision"
fi

# ---------------------------------------------------------------------------
# Apply patches
# ---------------------------------------------------------------------------
PATCH_BASE_URL=${PATCH_BASE_URL:-"https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/torchvision"}

# License exclusion patch — required; removes SWAG CC-BY-NC-4.0 licensed
# models (regnet.py, vision_transformer SWAG weights) from the wheel.
LICENSE_PATCH_FILE="0001-Exclude-source-that-has-commercial-license_v0.28.0.patch"
wget -q -O "${SCRIPT_DIR}/${LICENSE_PATCH_FILE}" "${PATCH_BASE_URL}/${LICENSE_PATCH_FILE}"
git apply "${SCRIPT_DIR}/${LICENSE_PATCH_FILE}"

# Patch out the git-sha injection in setup.py that breaks reproducible builds
sed -i '/elif sha != "Unknown":/,+1d' setup.py

# ---------------------------------------------------------------------------
# Build torchvision wheel
# ---------------------------------------------------------------------------
echo "Building torchvision wheel"

# Let torchvision's CMake find the installed torch
export TORCH_CMAKE_PREFIX=$($PYTHON -c 'import torch; print(torch.utils.cmake_prefix_path)')
export CMAKE_PREFIX_PATH="${TORCH_CMAKE_PREFIX}:${ROCM_PATH}:${CMAKE_PREFIX_PATH:-}"

export BUILD_VERSION="${PACKAGE_VERSION#v}"
export SETUPTOOLS_SCM_PRETEND_VERSION="${BUILD_VERSION}"

$PYTHON -m pip install --upgrade setuptools wheel

if ! MAX_JOBS=$(nproc) $PYTHON setup.py bdist_wheel --dist-dir "${SCRIPT_DIR}"; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Rename wheel to match ROCm naming convention (torchvision-0.28.0+rocm-...)
# This mirrors what torch-2.13.0+rocm does: the +rocm suffix signals the wheel
# was built against a ROCm torch. Only the filename is renamed; METADATA inside
# retains the plain version so strict validators see a consistent wheel.
PLAIN_WHL=$(ls "${SCRIPT_DIR}"/torchvision-${BUILD_VERSION}-*.whl)
ROCM_WHL="${PLAIN_WHL/torchvision-${BUILD_VERSION}-/torchvision-${BUILD_VERSION}+rocm-}"
mv "$PLAIN_WHL" "$ROCM_WHL"
echo "Renamed wheel to: $(basename $ROCM_WHL)"

# Install the wheel we just built so the import test can run
$PYTHON -m pip install "$ROCM_WHL"

# ---------------------------------------------------------------------------
# Import test
# ---------------------------------------------------------------------------
echo "Running import test"
cd "${SCRIPT_DIR}"

if ! $PYTHON -c "import torch; import torchvision; print('torchvision version:', torchvision.__version__)"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_Import_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Import_Success"
exit 0
