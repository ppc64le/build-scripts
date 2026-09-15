#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : fastsafetensors
# Version       : 0.4.0
# Source repo   : https://github.com/foundation-model-stack/fastsafetensors.git
# Tested on     : UBI:10 (ppc64le)
# Language      : Python, C++
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
# -----------------------------------------------------------------------------
#
# fastsafetensors builds a pybind11 C++ extension (ext.cpp) using a standard
# setuptools build — no CUDA/ROCm headers are needed at compile time because
# all GPU runtime symbols are loaded via dlopen() at runtime.
#
# Usage:
#   ./fastsafetensors_0.4.0_ubi_10.sh [0.4.0]
#
# Environment variables honoured (can be set before running):
#   PACKAGE_VERSION  - tag/branch to build (default: 0.4.0)
#   DEVPI_INDEX      - IBM ppc64le devpi wheel index URL
#                      (default: https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple)
#
# ---------------------------------------------------------------------------

set -e

PACKAGE_NAME=fastsafetensors
PACKAGE_VERSION=${1:-0.4.0}
PACKAGE_URL=https://github.com/foundation-model-stack/fastsafetensors.git
SCRIPT_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

DEVPI_INDEX=${DEVPI_INDEX:-"https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple"}

echo "=== fastsafetensors Build ==="
echo "  PACKAGE_VERSION : $PACKAGE_VERSION"
echo "  OS              : $OS_NAME"
echo "  DEVPI_INDEX     : $DEVPI_INDEX"
echo "============================="

# ---------------------------------------------------------------------------
# Install system build dependencies
# ---------------------------------------------------------------------------

# Python packages must appear first (wrapper script requirement).
yum install -y python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    git make

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

PYTHON=python3.12

# ---------------------------------------------------------------------------
# Clone
# ---------------------------------------------------------------------------
echo "Cloning fastsafetensors ${PACKAGE_VERSION}"
if [ -d "${SCRIPT_DIR}/${PACKAGE_NAME}" ]; then
    echo "${PACKAGE_NAME} directory already exists, reusing."
    cd "${SCRIPT_DIR}/${PACKAGE_NAME}"
    git checkout "$PACKAGE_VERSION"
else
    if ! git clone --branch "$PACKAGE_VERSION" "$PACKAGE_URL" "${SCRIPT_DIR}/${PACKAGE_NAME}"; then
        echo "------------------${PACKAGE_NAME}:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
        exit 1
    fi
    cd "${SCRIPT_DIR}/${PACKAGE_NAME}"
fi

# ---------------------------------------------------------------------------
# Install Python build dependencies
# ---------------------------------------------------------------------------
$PYTHON -m pip install --upgrade pip
$PYTHON -m pip install "setuptools>=78.1.1" wheel pybind11

# ---------------------------------------------------------------------------
# Build wheel
# ---------------------------------------------------------------------------
echo "Building fastsafetensors wheel"

export BUILD_VERSION="${PACKAGE_VERSION#v}"
export SETUPTOOLS_SCM_PRETEND_VERSION="${BUILD_VERSION}"

if ! $PYTHON -m pip wheel . --no-build-isolation --no-deps -w "${SCRIPT_DIR}/dist"; then
    echo "------------------${PACKAGE_NAME}:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi

FST_WHL=$(ls "${SCRIPT_DIR}/dist"/fastsafetensors-${BUILD_VERSION}-*.whl)
echo "Built wheel: $(basename "$FST_WHL")"

# ---------------------------------------------------------------------------
# Install wheel and test dependencies
# ---------------------------------------------------------------------------
# Install runtime dependency then the wheel itself
$PYTHON -m pip install "typer>=0.9.0"
$PYTHON -m pip install "$FST_WHL"

# torch, safetensors and numpy are needed by the unit tests (conftest generates
# a tiny GPT-2 safetensors fixture; safetensors.torch.save_file() requires numpy).
# torch/safetensors are not on PyPI for ppc64le — pull from the IBM devpi index.
echo "Installing test dependencies from devpi index: ${DEVPI_INDEX}"
$PYTHON -m pip install --prefer-binary \
    --extra-index-url "${DEVPI_INDEX}" \
    torch \
    "safetensors>=0.4.0" \
    "pytest>=9.0.3" \
    numpy

# ---------------------------------------------------------------------------
# Import test
# ---------------------------------------------------------------------------
echo "Running import test"
cd "${SCRIPT_DIR}"

if ! $PYTHON -c "import fastsafetensors; print('fastsafetensors version:', fastsafetensors.__version__)"; then
    echo "------------------${PACKAGE_NAME}:install_success_but_import_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_Import_Fails"
    exit 2
fi

# ---------------------------------------------------------------------------
# C++ extension smoke test
# Validates the compiled pybind11 extension: alignment constant, dlopen of
# GPU runtime libs (gracefully absent on CPU-only hosts), CUDA/HIP detection.
# ---------------------------------------------------------------------------
echo "Running C++ extension smoke test"
if ! $PYTHON "${SCRIPT_DIR}/${PACKAGE_NAME}/tests/smoke_import_cpp.py"; then
    echo "------------------${PACKAGE_NAME}:smoke_test_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Smoke_Test_Fails"
    exit 2
fi

# ---------------------------------------------------------------------------
# Unit tests
# Pure-Python tests that run on CPU with no GPU required:
#   test_config.py   — LoaderConfig / load_config API
#   test_ep_slice.py — expert-parallel range math + nogds partial-read I/O
#                      (GPU-specific sub-tests are auto-skipped via skipif)
#   test_planner.py  — pipeline budget/planner logic
#   test_fastsafetensors.py — core loader round-trip on CPU
#
# conftest.py (in tests/unit) does `from platform_utils import ...` which
# requires tests/unit to be on sys.path — achieved by running pytest from
# that directory.
# ---------------------------------------------------------------------------
echo "Running unit tests"
TESTS_DIR="${SCRIPT_DIR}/${PACKAGE_NAME}/tests/unit"
cd "$TESTS_DIR"

if ! CUDA_VISIBLE_DEVICES="" TEST_FASTSAFETENSORS_FRAMEWORK=torch \
    $PYTHON -m pytest -s \
        test_config.py \
        test_ep_slice.py \
        test_planner.py \
        test_fastsafetensors.py; then
    echo "------------------${PACKAGE_NAME}:unit_tests_fail--------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Unit_Tests_Fail"
    exit 2
fi

cd "${SCRIPT_DIR}"

echo "------------------${PACKAGE_NAME}:install_&_all_tests_success---------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Tests_Success"
exit 0
