#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : xgboost
# Version          : v3.4.0
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
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=xgboost
PACKAGE_VERSION=${1:-v3.4.0}
PACKAGE_URL=https://github.com/dmlc/xgboost

CURRENT_DIR=$(pwd)

NUMPY_VERSION=2.5.0
PYARROW_VERSION=25.0.0
XGBOOST_SDIST_VERSION="${PACKAGE_VERSION#v}"   # strip leading 'v' for PyPI URL

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    gcc-toolset-15-gcc-gfortran gcc-toolset-15-libatomic-devel \
    cmake ninja-build make \
    openblas-devel libjpeg-turbo-devel pkg-config \
    openssl-devel libffi-devel zlib-devel \
    wget xz-devel bzip2-devel lz4-devel \
    libevent libtool patch tzdata binutils \
    brotli brotli-devel perl-Unicode-Normalize \
    libatomic graphviz \
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

export CC="$(which gcc)"
export CXX="$(which g++)"


# ---------------------------------------------------------------------------
# Python build tools and runtime dependencies
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build
python3.14 -m pip install \
    "meson-python>=0.18.0" "Cython>=3.0.6" meson ninja patchelf \
    packaging pathspec pluggy trove-classifiers scikit-build-core hatchling \
    pytest hypothesis "pandas==3.0.5" graphviz Pillow matplotlib \
    "numpy==${NUMPY_VERSION}"

python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "scipy==1.18.0" "scikit-learn==1.9.0"

# ===========================================================================
# Build pyarrow 25.0.0 from source
# (Approach from build-scripts/o/onnx/onnx_1.21.0_ubi_10.2.sh)
# ===========================================================================

# gcc-toolset-15 ld does not find the system libatomic; create the unversioned
# symlink that -latomic requires.
if [[ ! -e /usr/lib64/libatomic.so ]]; then
    ln -s /usr/lib64/libatomic.so.1 /usr/lib64/libatomic.so
    echo "Created /usr/lib64/libatomic.so symlink for Arrow C++ build"
fi

# ---------------------------------------------------------------------------
# Step 1: Build and install Arrow C++ 25.0.0 (BUNDLED deps — no manual
#         protobuf / gRPC / c-ares / re2 build needed)
# ---------------------------------------------------------------------------
echo "--- Building Arrow C++ ${PYARROW_VERSION} ---"
ARROW_TARBALL="https://archive.apache.org/dist/arrow/arrow-${PYARROW_VERSION}/apache-arrow-${PYARROW_VERSION}.tar.gz"
ARROW_SRC="${CURRENT_DIR}/arrow_src"
mkdir -p "${ARROW_SRC}"
curl -sSL --fail -o "${ARROW_SRC}/apache-arrow-${PYARROW_VERSION}.tar.gz" "${ARROW_TARBALL}"
tar -xzf "${ARROW_SRC}/apache-arrow-${PYARROW_VERSION}.tar.gz" -C "${ARROW_SRC}"
ARROW_CPP_SRC="${ARROW_SRC}/apache-arrow-${PYARROW_VERSION}/cpp"

mkdir -p "${ARROW_CPP_SRC}/build"
cmake -S "${ARROW_CPP_SRC}" -B "${ARROW_CPP_SRC}/build" \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_EXE_LINKER_FLAGS="-L/usr/lib64" \
    -DCMAKE_SHARED_LINKER_FLAGS="-L/usr/lib64" \
    -DCMAKE_MODULE_LINKER_FLAGS="-L/usr/lib64" \
    -DARROW_BUILD_STATIC=OFF \
    -DARROW_BUILD_SHARED=ON \
    -DARROW_PYTHON=ON \
    -DARROW_DATASET=ON \
    -DARROW_PARQUET=ON \
    -DARROW_ACERO=ON \
    -DARROW_COMPUTE=ON \
    -DARROW_CSV=ON \
    -DARROW_JSON=ON \
    -DARROW_IPC=ON \
    -DARROW_WITH_ZLIB=ON \
    -DARROW_WITH_LZ4=ON \
    -DARROW_WITH_SNAPPY=ON \
    -DARROW_WITH_ZSTD=ON \
    -DARROW_WITH_BZ2=ON \
    -DARROW_DEPENDENCY_SOURCE=BUNDLED \
    -DARROW_VERBOSE_THIRDPARTY_BUILD=OFF
cmake --build "${ARROW_CPP_SRC}/build" --parallel "$(nproc)"
cmake --install "${ARROW_CPP_SRC}/build"
ldconfig

export Arrow_DIR=/usr/local/lib/cmake/Arrow
export ArrowDataset_DIR=/usr/local/lib/cmake/ArrowDataset
export Parquet_DIR=/usr/local/lib/cmake/Parquet
# Persist so pyarrow can dlopen libarrow*.so at validation time
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:${LD_LIBRARY_PATH:-}
echo "/usr/local/lib"    > /etc/ld.so.conf.d/arrow-local.conf
echo "/usr/local/lib64" >> /etc/ld.so.conf.d/arrow-local.conf
ldconfig
echo "Arrow C++ ${PYARROW_VERSION} installed successfully"

# ---------------------------------------------------------------------------
# Step 2: Build pyarrow wheel against the installed Arrow C++
# ---------------------------------------------------------------------------
echo "--- Building pyarrow ${PYARROW_VERSION} ---"
python3.14 -m pip install "scikit-build-core>=0.11.0" cython "setuptools_scm[toml]>=8"
export PYARROW_REQUIRE_STUB_DOCSTRINGS=OFF
export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)
PYARROW_SDIST="https://files.pythonhosted.org/packages/27/f3/95428098d1fa7d04432fb750eed06b41304c2f6a5d3319985e64db2d9d41/pyarrow-${PYARROW_VERSION}.tar.gz"
python3.14 -m pip install --no-build-isolation "${PYARROW_SDIST}"
echo "pyarrow ${PYARROW_VERSION} installed successfully"

# ===========================================================================
# Build xgboost 3.4.0 from source (scikit-build-core / cmake sdist)
# ===========================================================================
echo "--- Building xgboost ${XGBOOST_SDIST_VERSION} ---"

WHEEL_DIR="${CURRENT_DIR}/wheels"
mkdir -p "${WHEEL_DIR}"

# xgboost sdist — scikit-build-core drives the cmake build (USE_CUDA=OFF by
# default on CPU-only targets).  --no-build-isolation keeps the numpy/scipy
# already installed above visible to the build backend.
XGBOOST_SDIST="https://files.pythonhosted.org/packages/7d/11/2b1de4cb9b7eeb042ca49c7d3b3ed2b77e7645ee6c0f99cf616716f3e8d7/xgboost-${XGBOOST_SDIST_VERSION}.tar.gz"

if ! python3.14 -m pip wheel \
        --no-build-isolation \
        --no-deps \
        -w "${WHEEL_DIR}" \
        "${XGBOOST_SDIST}"; then
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
python3.14 -m pip install --no-deps --force-reinstall "${WHL}"

# ---------------------------------------------------------------------------
# Run test suite (skip GPU, distributed, and test files that require
# a live cluster or CUDA)
# ---------------------------------------------------------------------------
# Fetch the source tree for tests (not needed for the wheel itself)
cd "${CURRENT_DIR}"
git clone --depth 1 --branch "${PACKAGE_VERSION}" "${PACKAGE_URL}" xgboost_src
cd xgboost_src

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
