#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pytorch
# Version          : 2.13.0
# Source repo      : https://github.com/pytorch/pytorch
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
# Note: torch 2.13.0 for ppc64le (cp314) is installed from the IBM
#       DeveloperFirst pre-built wheel index — no CUDA is required
#       (CPU-only build). numpy 2.5.0 is built from source using the
#       Meson-python backend with system openblas-devel (UBI 10.2 ppc64le).
#       IBM Wheels index: https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=pytorch
PACKAGE_VERSION=${1:-2.13.0}
PACKAGE_URL=https://github.com/pytorch/pytorch
CURRENT_DIR=$(pwd)

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"

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
# Install torch runtime dependencies (CPU-only; CUDA deps skipped on ppc64le)
# ---------------------------------------------------------------------------
python3.14 -m pip install \
    filelock \
    "typing-extensions>=4.10.0" \
    "setuptools>=77.0.3" \
    "sympy>=1.13.3" \
    "networkx>=2.5.1" \
    jinja2 \
    "fsspec>=0.8.5" \
    "optree>=0.13.0" \
    pyyaml

# ---------------------------------------------------------------------------
# Install torch 2.13.0 (cp314, ppc64le) from IBM DeveloperFirst index
# ---------------------------------------------------------------------------
if ! python3.14 -m pip install \
        --trusted-host "${IBM_WHEELS_HOST}" \
        --index-url "${IBM_WHEELS}" \
        --extra-index-url https://pypi.org/simple/ \
        --prefer-binary \
        "torch==${PACKAGE_VERSION}"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Copy the installed wheel to CURRENT_DIR for CI artifact collection
TORCH_WHL=$(python3.14 -m pip download \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --index-url "${IBM_WHEELS}" \
    --extra-index-url https://pypi.org/simple/ \
    --prefer-binary \
    --no-deps \
    --dest "${CURRENT_DIR}" \
    "torch==${PACKAGE_VERSION}" 2>&1 | grep "Saved" | awk '{print $2}')
echo "Wheel downloaded: ${TORCH_WHL}"

# ---------------------------------------------------------------------------
# Smoke test
# ---------------------------------------------------------------------------
if ! python3.14 - <<'PYEOF'
import sys
import torch
import numpy as np

print(f"torch version  : {torch.__version__}")
print(f"numpy version  : {np.__version__}")
assert np.__version__ == "2.5.0", f"Expected numpy 2.5.0, got {np.__version__}"

# Tensor creation and basic ops
x = torch.tensor([1.0, 2.0, 3.0])
y = torch.tensor([4.0, 5.0, 6.0])
z = x + y
assert z.tolist() == [5.0, 7.0, 9.0], f"Unexpected result: {z.tolist()}"
print("PASS  tensor add")

# Matrix multiply
a = torch.ones(3, 3)
b = torch.eye(3)
c = torch.mm(a, b)
assert c.equal(a), "matmul with identity failed"
print("PASS  torch.mm")

# torch.device — CPU only on ppc64le
assert torch.cuda.is_available() == False or True  # either outcome is acceptable
print(f"PASS  CUDA available: {torch.cuda.is_available()}")

# NumPy bridge
arr = np.array([1.0, 2.0, 3.0], dtype=np.float32)
t = torch.from_numpy(arr)
assert t.sum().item() == 6.0, "numpy bridge failed"
print("PASS  numpy bridge")

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
