#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : torchvision
# Version          : 0.28.0
# Source repo      : https://github.com/pytorch/vision
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
# Note: torchvision 0.28.0 requires torch==2.13.0 (installed from the IBM
#       DeveloperFirst wheels index — no ppc64le wheel on PyPI).
#       torchvision itself has no ppc64le pre-built wheel on PyPI or IBM index
#       so it is built from source using setup.py + torch.utils.cpp_extension.
#       FORCE_CUDA=0 disables GPU; libjpeg-turbo, libpng, libwebp are installed
#       for image codec support.
#       numpy 2.5.0 is built from source using the Meson-python backend with
#       system openblas-devel (UBI 10.2 ppc64le).
#       IBM Wheels index: https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=torchvision
PACKAGE_VERSION=${1:-0.28.0}
PACKAGE_URL=https://github.com/pytorch/vision
PACKAGE_DIR=vision
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
    make cmake ninja-build \
    openblas-devel \
    pkg-config \
    libjpeg-turbo-devel libpng-devel libwebp-devel \
    zlib-devel openssl-devel libffi-devel \
    which curl tar

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
python3.14 -m pip install --upgrade pip setuptools wheel build packaging
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
# torchvision setup.py imports torch at build time — must be installed first.
# ---------------------------------------------------------------------------
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --index-url "${IBM_WHEELS}" \
    --extra-index-url https://pypi.org/simple/ \
    --prefer-binary \
    "torch==${TORCH_VERSION}"

python3.14 -m pip install pillow requests

# ---------------------------------------------------------------------------
# Clone torchvision and checkout v0.28.0
# ---------------------------------------------------------------------------
cd "${CURRENT_DIR}"
git clone "${PACKAGE_URL}" "${PACKAGE_DIR}"
cd "${PACKAGE_DIR}"

if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# ---------------------------------------------------------------------------
# Build torchvision wheel (CPU-only: FORCE_CUDA=0, no NVJPEG)
# setup.py uses torch.utils.cpp_extension — requires torch installed above.
# ---------------------------------------------------------------------------
export FORCE_CUDA=0
export TORCHVISION_USE_NVJPEG=0

if ! python3.14 setup.py bdist_wheel --dist-dir="${WHEEL_DIR}"; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

cp "${WHEEL_DIR}"/*.whl "${CURRENT_DIR}/" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Install wheel and test
# ---------------------------------------------------------------------------
python3.14 -m pip install installer
WHL=$(ls "${WHEEL_DIR}"/torchvision-*.whl | head -1)
python3.14 -m installer "${WHL}"

cd "${CURRENT_DIR}"

if ! python3.14 - <<'PYEOF'
import sys
import torch
import torchvision
import torchvision.transforms as T
import numpy as np
from PIL import Image

print(f"torch version       : {torch.__version__}")
print(f"torchvision version : {torchvision.__version__}")

# Basic transform pipeline
img = Image.fromarray(np.zeros((64, 64, 3), dtype=np.uint8))
transform = T.Compose([
    T.Resize((32, 32)),
    T.ToTensor(),
    T.Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5]),
])
tensor = transform(img)
assert tensor.shape == (3, 32, 32), f"Unexpected shape: {tensor.shape}"
print("PASS  transform pipeline")

# ops: nms
boxes  = torch.tensor([[0.0, 0.0, 1.0, 1.0], [0.1, 0.1, 1.1, 1.1]])
scores = torch.tensor([0.9, 0.8])
keep   = torchvision.ops.nms(boxes, scores, iou_threshold=0.5)
assert len(keep) >= 1, "nms returned no boxes"
print("PASS  torchvision.ops.nms")

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
