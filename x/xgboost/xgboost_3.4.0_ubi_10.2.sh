#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : xgboost
# Version          : 3.4.0
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
# Note: xgboost is the CPU-only variant of XGBoost (USE_CUDA=OFF).
#       Built from the GitHub source tree using CMake + Ninja, then the
#       Python wheel is produced from python-package/ via pip wheel.
#       nvidia-nccl-cu12 is removed from pyproject.toml before wheel build
#       as it is not available on ppc64le.
#       numpy 2.5.0 is built from source (Meson-python backend) 
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=xgboost
PACKAGE_VERSION=${1:-3.4.0}
PACKAGE_URL=https://github.com/dmlc/xgboost
PACKAGE_DIR=xgboost

CURRENT_DIR=$(pwd)
NUMPY_VERSION=2.5.0

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    gcc-toolset-15-gcc-gfortran \
    cmake ninja-build make \
    openblas-devel pkg-config \
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
# Python build tools and test dependencies
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build
python3.14 -m pip install "meson-python>=0.18.0" "Cython>=3.0.6" meson ninja patchelf
python3.14 -m pip install packaging pathspec pluggy trove-classifiers scikit-build-core hatchling
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
python3.14 -m pip install \
    --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "pyarrow==23.0.1"
python3.14 -m pip install pytest hypothesis pandas graphviz

# ---------------------------------------------------------------------------
# Build numpy from source
# ---------------------------------------------------------------------------
echo "=== Building numpy ${NUMPY_VERSION} from source ==="
cd "${CURRENT_DIR}"
git clone https://github.com/numpy/numpy numpy-src
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
        --outdir="${CURRENT_DIR}/numpy-wheels/"; then
    echo "ERROR: numpy build failed"
    exit 1
fi

NUMPY_WHL=$(find "${CURRENT_DIR}/numpy-wheels" -name "numpy-*.whl" | head -1)
echo "Installing numpy wheel: ${NUMPY_WHL}"
python3.14 -m pip install --no-deps --force-reinstall "${NUMPY_WHL}"
echo "numpy ${NUMPY_VERSION} installed successfully"

# ---------------------------------------------------------------------------
# Clone and checkout xgboost
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

git submodule update --init

export SRC_DIR=$(pwd)

# ---------------------------------------------------------------------------
# Build the shared library via CMake (CPU-only)
# ---------------------------------------------------------------------------
mkdir -p build
cd build

cmake \
    -DCMAKE_INSTALL_PREFIX="${CURRENT_DIR}/output" \
    -DUSE_CUDA=OFF \
    -DUSE_OPENMP=ON \
    -DUSE_NCCL=OFF \
    ..

make VERBOSE=1 -j"$(nproc)"
cd "${SRC_DIR}"

# ---------------------------------------------------------------------------
# Build Python wheel from python-package/
# Remove nvidia-nccl-cu12 dependency — not available on ppc64le.
# ---------------------------------------------------------------------------
cd "${SRC_DIR}/python-package"
sed -i '/nvidia-nccl-cu12/d' pyproject.toml

WHEEL_DIR="${CURRENT_DIR}/wheels"
mkdir -p "${WHEEL_DIR}"

if ! python3.14 -m pip wheel -w "${WHEEL_DIR}" -v . --no-build-isolation --no-deps; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Copy wheel to CURRENT_DIR for create_wheel_wrapper.sh compatibility
cp "${WHEEL_DIR}"/*.whl "${CURRENT_DIR}/" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Install runtime dependencies and the wheel itself
# ---------------------------------------------------------------------------
python3.14 -m pip install scipy

WHL=$(ls "${WHEEL_DIR}"/xgboost-*.whl | head -1)
python3.14 -m pip install --no-deps --force-reinstall "${WHL}"

# ---------------------------------------------------------------------------
# Run test suite (skip GPU, distributed, and unavailable extras)
# ---------------------------------------------------------------------------
cd "${SRC_DIR}"

if ! python3.14 -m pytest tests/ \
    --ignore=tests/ci_build/test_r_package.py \
    --ignore=tests/python/test_cli.py \
    --ignore=tests/python/test_demos.py \
    --ignore=tests/python/test_openmp.py \
    --ignore=tests/python/test_tracker.py \
    --ignore=tests/python-gpu/ \
    --ignore=tests/test_distributed/test_gpu_with_dask \
    --ignore=tests/test_distributed/test_with_dask \
    --ignore=tests/test_distributed/test_with_spark \
    --ignore=tests/test_distributed/test_gpu_with_spark \
    --ignore=tests/test_distributed/test_federated \
    --ignore=tests/test_distributed/test_gpu_federated \
    --ignore=tests/python-sycl \
    --ignore=tests/cross-platform \
    --ignore=tests/python/test_with_sklearn.py \
    --disable-warnings \
    -p no:xfail -v; then
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
