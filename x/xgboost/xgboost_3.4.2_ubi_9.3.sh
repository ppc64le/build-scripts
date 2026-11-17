#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : xgboost
# Version          : v3.4.2
# Source repo      : https://github.com/dmlc/xgboost
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : vrushanaik <Vrusha.Naik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=xgboost
PACKAGE_VERSION=${1:-v3.4.2}
PACKAGE_URL=https://github.com/dmlc/xgboost

CURRENT_DIR=$(pwd)
WHEEL_DIR="${CURRENT_DIR}/wheels"
mkdir -p "${WHEEL_DIR}"

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"

# ---------------------------------------------------------------------------
# Install system dependencies
# ---------------------------------------------------------------------------
yum install -y --allowerasing git wget make cmake ninja-build \
    gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ \
    gcc-toolset-13-gcc-gfortran gcc-toolset-13-libatomic-devel \
    python3.12 python3.12-devel python3.12-pip openssl-devel \
    libffi-devel zlib-devel bzip2-devel xz-devel lz4-devel \
    libevent libtool patch tzdata binutils which tar graphviz \
    libjpeg-turbo-devel freetype-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH:-}

export CC="$(which gcc)"
export CXX="$(which g++)"

# ---------------------------------------------------------------------------
# Clone and install OpenBLAS from source
# ---------------------------------------------------------------------------
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init
make -j$(nproc) TARGET=POWER9 BUILD_BFLOAT16=1 BINARY=64 USE_OPENMP=1 USE_THREAD=1 NUM_THREADS=120 DYNAMIC_ARCH=1 INTERFACE64=0
make install PREFIX=/usr/local
export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:${PKG_CONFIG_PATH:-}
cd "${CURRENT_DIR}"

# ---------------------------------------------------------------------------
# Python build tools and runtime dependencies
# ---------------------------------------------------------------------------
python3.12 -m pip install --upgrade pip setuptools wheel build
python3.12 -m pip install \
    "meson-python>=0.17.0" "Cython>=3.0.6" meson ninja patchelf \
    packaging pathspec pluggy trove-classifiers scikit-build-core \
    pytest hypothesis graphviz joblib threadpoolctl

# Compiled packages from the IBM devpi wheel index (ppc64le prebuilt wheels)
# so numpy/pandas/Pillow/matplotlib/scipy/scikit-learn are not built from source.
python3.12 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "numpy==2.5.0" "scipy==1.18.0"  pandas Pillow matplotlib scikit-learn pyarrow

# ===========================================================================
# Clone xgboost and build C++ / Python wheel from source
# ===========================================================================
echo "--- Cloning xgboost ${PACKAGE_VERSION} ---"
git clone --depth 1 --branch "${PACKAGE_VERSION}" --recursive "${PACKAGE_URL}" xgboost_src
cd xgboost_src

echo "--- Building xgboost C++ library ---"
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DENABLE_ALL_WARNINGS=OFF \
      ..
cmake --build . --parallel "$(nproc)"
cmake --install .
ldconfig
cd ..

echo "--- Building xgboost Python wheel ---"
cd python-package
if ! python3.12 -m pip wheel \
        --no-build-isolation \
        --no-deps \
        -w "${WHEEL_DIR}" \
        .; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

cp "${WHEEL_DIR}"/*.whl "${CURRENT_DIR}/" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Install the xgboost wheel
# ---------------------------------------------------------------------------
WHL=$(ls "${WHEEL_DIR}"/xgboost-*.whl | head -1)
echo "Installing xgboost wheel: ${WHL}"
python3.12 -m pip install --no-deps --force-reinstall "${WHL}"

# ---------------------------------------------------------------------------
# Import check & run test suite
# ---------------------------------------------------------------------------
echo "Import check"
python3.12 -c "import xgboost; print(xgboost.__version__)"

cd "${CURRENT_DIR}/xgboost_src"

if ! python3.12 -m pytest tests/ \
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
