#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : xgboost-cpu
# Version          : 3.4.1
# Source repo      : https://github.com/dmlc/xgboost
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
# Note: xgboost-cpu is the CPU-only variant of XGBoost (USE_CUDA=OFF).
#       It is built from the PyPI source distribution (sdist) which
#       includes the C++ tree under cpp_src/ and uses scikit-build-core
#       as the PEP 517 backend (CMake + Ninja internally).
#       python3.14 requires scikit-build-core >=0.11.0 which is fetched
#       at build time by pip via the build isolation requirements.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=xgboost-cpu
PACKAGE_VERSION=${1:-3.4.1}
PACKAGE_URL=https://github.com/dmlc/xgboost
CURRENT_DIR=$(pwd)
WHEEL_DIR="${CURRENT_DIR}/wheels"
mkdir -p "${WHEEL_DIR}"

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    cmake ninja-build make \
    openssl-devel libffi-devel zlib-devel \
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
echo "Using cmake: $(cmake --version | head -1)"
echo "Using python: $(python3.14 --version)"

# ---------------------------------------------------------------------------
# Python build tools
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build
python3.14 -m pip install "scikit-build-core>=0.11.0" cmake ninja

# ---------------------------------------------------------------------------
# Download xgboost-cpu source distribution from PyPI
# The sdist bundles the C++ tree under cpp_src/ — no git submodule needed.
# ---------------------------------------------------------------------------
SDIST_URL="https://files.pythonhosted.org/packages/99/98/c35e165aff81e43b43411662219764abbd246adae2547d360b23194cf75f/xgboost_cpu-${PACKAGE_VERSION}.tar.gz"

cd "${CURRENT_DIR}"
curl -sSL --fail -o "xgboost_cpu-${PACKAGE_VERSION}.tar.gz" "${SDIST_URL}"
tar -xzf "xgboost_cpu-${PACKAGE_VERSION}.tar.gz"
cd "xgboost_cpu-${PACKAGE_VERSION}"

# ---------------------------------------------------------------------------
# Build the wheel via scikit-build-core (CMake + Ninja, CPU-only)
# USE_CUDA=OFF is the default; USE_OPENMP=ON for multi-core ppc64le perf.
# ---------------------------------------------------------------------------
export CMAKE_ARGS="-DUSE_CUDA=OFF -DUSE_OPENMP=ON -DUSE_NCCL=OFF"

if ! python3.14 -m build --wheel --no-isolation --outdir="${WHEEL_DIR}"; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Copy wheel to CURRENT_DIR for create_wheel_wrapper.sh compatibility
cp "${WHEEL_DIR}"/*.whl "${CURRENT_DIR}/" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Install wheel dependencies and the wheel itself
# Pip 26+ blocks file:// URIs to non-localhost paths; downgrade to pip 25
# (last version without this restriction) before the local wheel install.
# ---------------------------------------------------------------------------
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
python3.14 -m pip install \
    --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "numpy==2.5.1" scipy

# Install the wheel using python -m installer (bypasses pip's URL checks)
WHL=$(ls "${WHEEL_DIR}"/xgboost_cpu-*.whl | head -1)
python3.14 -m pip install installer
python3.14 -m installer "${WHL}"

# Return to a neutral directory so Python doesn't pick up the source tree
cd "${CURRENT_DIR}"

if ! python3.14 - <<'PYEOF'
import sys
import xgboost as xgb
import numpy as np

print(f"xgboost version: {xgb.__version__}")

# Basic DMatrix and training smoke test
X = np.array([[1.0, 2.0], [3.0, 4.0], [5.0, 6.0], [7.0, 8.0]])
y = np.array([0, 1, 0, 1])
dtrain = xgb.DMatrix(X, label=y)

params = {
    "max_depth": 2,
    "eta": 0.3,
    "objective": "binary:logistic",
    "device": "cpu",
}
bst = xgb.train(params, dtrain, num_boost_round=3)
preds = bst.predict(dtrain)
assert len(preds) == 4, f"Expected 4 predictions, got {len(preds)}"
print(f"Predictions: {preds}")
print("PASS  xgboost basic train/predict")
print("All tests passed.")
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
