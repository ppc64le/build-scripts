#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : torchdata
# Version          : 0.11.0
# Source repo      : https://github.com/pytorch/data
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# Note: torchdata 0.11.0 ships as a pure-Python wheel (py3-none-any) on PyPI.
#       torch 2.13.0 is installed from the IBM DeveloperFirst wheels index.
#       numpy 2.5.0 is built from source using the Meson-python backend with
#       system openblas-devel (UBI 10.2 ppc64le).
#       IBM Wheels index: https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=torchdata
PACKAGE_VERSION=${1:-0.11.0}
PACKAGE_URL=https://github.com/pytorch/data
CURRENT_DIR=$(pwd)
WHEEL_DIR="${CURRENT_DIR}/wheels"
mkdir -p "${WHEEL_DIR}"

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"
TORCH_VERSION="2.13.0"

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    gcc-toolset-15-gcc-gfortran \
    cmake ninja-build \
    openblas-devel \
    pkg-config \
    make which curl tar \
    libffi-devel zlib-devel openssl-devel

# UBI 10 dropped SCL — guard block
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
echo "Using python: $(python3.14 --version)"

# ---------------------------------------------------------------------------
# Python build tools
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build
python3.14 -m pip install "meson-python>=0.18.0" "Cython>=3.0.6" meson ninja patchelf

# ---------------------------------------------------------------------------
# Build numpy 2.5.0 from source (Meson-python + system openblas-devel)
# ---------------------------------------------------------------------------
NUMPY_VERSION=2.5.0
NUMPY_URL=https://github.com/numpy/numpy

git clone "${NUMPY_URL}" numpy-src
cd numpy-src

if git rev-parse "v${NUMPY_VERSION}" &>/dev/null; then
    git checkout "v${NUMPY_VERSION}"
elif git rev-parse "${NUMPY_VERSION}" &>/dev/null; then
    git checkout "${NUMPY_VERSION}"
else
    echo "ERROR: No git tag found for numpy version '${NUMPY_VERSION}'"
    exit 1
fi

git submodule sync --recursive
git submodule update --init --recursive

export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/share/pkgconfig:${PKG_CONFIG_PATH:-}"

if ! python3.14 -m build --wheel --no-isolation \
        -Csetup-args="-Dblas=openblas" \
        -Csetup-args="-Dlapack=openblas" \
        --outdir="${CURRENT_DIR}/"; then
    echo "------------------numpy:Install_fails-------------------------------------"
    echo "${NUMPY_URL} numpy"
    echo "numpy  |  ${NUMPY_URL} | ${NUMPY_VERSION} | GitHub | Fail |  Install_Fails"
    exit 1
fi

NUMPY_WHL=$(find "${CURRENT_DIR}" -maxdepth 1 -name "numpy-*.whl" | head -1)
echo "Installing numpy wheel: ${NUMPY_WHL}"
python3.14 -m pip install "${NUMPY_WHL}"

cd "${CURRENT_DIR}"

# ---------------------------------------------------------------------------
# Install torch 2.13.0 from IBM DeveloperFirst index
# ---------------------------------------------------------------------------
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --index-url "${IBM_WHEELS}" \
    --extra-index-url https://pypi.org/simple/ \
    --prefer-binary \
    "torch==${TORCH_VERSION}"

# ---------------------------------------------------------------------------
# Download torchdata wheel from PyPI (pure-Python, no compilation needed)
# ---------------------------------------------------------------------------
python3.14 -m pip download \
    --no-deps \
    --dest "${WHEEL_DIR}" \
    "torchdata==${PACKAGE_VERSION}"

# ---------------------------------------------------------------------------
# Install torchdata wheel + runtime dependencies
# ---------------------------------------------------------------------------
python3.14 -m pip install urllib3 requests
python3.14 -m pip install installer
WHL=$(ls "${WHEEL_DIR}"/torchdata-*.whl | head -1)
python3.14 -m installer "${WHL}"

cp "${WHEEL_DIR}"/*.whl "${CURRENT_DIR}/" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Smoke test
# ---------------------------------------------------------------------------
if ! python3.14 - <<'PYEOF'
import sys
import torch
import torchdata

print(f"torch version     : {torch.__version__}")
print(f"torchdata version : {torchdata.__version__}")

# torchdata 0.11.0 is a minimal release — datapipes were removed.
# Verify the package is importable and version matches.
assert torchdata.__version__.startswith("0.11.0"), \
    f"Unexpected version: {torchdata.__version__}"
print("PASS  torchdata import and version check")

# Verify torch dependency is satisfied (torch >= 2)
from packaging.version import Version
assert Version(torch.__version__.split("+")[0]) >= Version("2.0.0"), \
    f"torch too old: {torch.__version__}"
print(f"PASS  torch >= 2.0.0 ({torch.__version__})")

print("\nAll tests passed.")
sys.exit(0)
PYEOF
then
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
