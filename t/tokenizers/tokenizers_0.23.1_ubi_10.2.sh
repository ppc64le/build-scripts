#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tokenizers
# Version       : v0.23.1
# Source repo   : https://github.com/huggingface/tokenizers
# Tested on     : UBI:10.2
# Language      : C,Python
# Ci-Check      : True
# Script License: Apache License 2.0
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# platform using the mentioned version of the package.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=tokenizers
PACKAGE_VERSION=${1:-v0.23.1}
PACKAGE_URL=https://github.com/huggingface/tokenizers
PACKAGE_DIR=tokenizers/bindings/python

PYTHON_VERSION=3.14
NUMPY_VERSION=2.5.0
PYARROW_VERSION=25.0.0

# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------

echo "------------------ Installing system dependencies ------------------"

yum install -y \
    wget \
    gcc \
    gcc-c++ \
    gcc-gfortran \
    git \
    make \
    python3.14 \
    python3.14-devel \
    python3.14-pip \
    openssl-devel \
    cmake \
    unzip \
    rust \
    cargo

echo "------------------ Upgrading Python build tools ------------------"

python3.14 -m pip install --upgrade \
    pip \
    setuptools \
    wheel \
    build \
    maturin

# -----------------------------------------------------------------------------
# Build and install PyArrow 25.0.0
# -----------------------------------------------------------------------------

echo "------------------ Cloning PyArrow ${PYARROW_VERSION} ------------------"

git clone https://github.com/apache/arrow.git
cd arrow

git checkout apache-arrow-25.0.0
git submodule update --init --recursive

export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA="${PWD}/testing/data"

echo "------------------ Applying PyArrow fixes ------------------"

# Fix Cython 3.x nogil/except syntax compatibility.
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' \
    python/pyarrow/error.pxi \
    python/pyarrow/includes/libarrow.pxd \
    python/pyarrow/lib.pxd \
    python/pyarrow/includes/libarrow_fs.pxd

# Fix generated Cython code using &&.
sed -i -E 's/\&\&/\&/g' \
    python/pyarrow/error.pxi \
    python/pyarrow/includes/libarrow.pxd \
    python/pyarrow/lib.pxd \
    python/pyarrow/includes/libarrow_fs.pxd

# Fix noexcept compatibility issues.
sed -i '/cdef object alloc_c_schema(ArrowSchema\*\* c_schema)/s/ noexcept//' \
    python/pyarrow/types.pxi

sed -i '/cdef object alloc_c_array(ArrowArray\*\* c_array)/s/ noexcept//' \
    python/pyarrow/types.pxi

sed -i '/cdef object alloc_c_stream(ArrowArrayStream\*\* c_stream)/s/ noexcept//' \
    python/pyarrow/types.pxi

echo "PyArrow fixes applied."

mkdir -p dist

export CXX=g++
export CC=gcc
export ARROW_HOME=$(pwd)/dist
export PYARROW_BUNDLE_ARROW_CPP=1
export LD_LIBRARY_PATH=${ARROW_HOME}/lib64:${ARROW_HOME}/lib:${LD_LIBRARY_PATH}
export CMAKE_PREFIX_PATH=${ARROW_HOME}/lib64/cmake:${ARROW_HOME}/lib/cmake:${CMAKE_PREFIX_PATH}

# -----------------------------------------------------------------------------
# PyArrow build dependencies
# -----------------------------------------------------------------------------

echo "------------------ Installing PyArrow build dependencies ------------------"

python3.14 -m pip install -r python/requirements-build.txt

python3.14 -m pip install \
    cython \
    wheel \
    six \
    setuptools \
    numpy==${NUMPY_VERSION}

mkdir -p cpp/build
cd cpp/build

# -----------------------------------------------------------------------------
# Build Arrow C++
# -----------------------------------------------------------------------------

echo "------------------ Configuring Arrow C++ ------------------"

cmake \
    -DCMAKE_INSTALL_PREFIX=${ARROW_HOME} \
    -DCMAKE_INSTALL_LIBDIR=lib64 \
    -DCMAKE_BUILD_TYPE=Release \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_COMPUTE=ON \
    -DARROW_CSV=ON \
    -DARROW_DATASET=ON \
    -DARROW_FILESYSTEM=ON \
    -DARROW_HDFS=ON \
    -DARROW_JSON=ON \
    -DARROW_PARQUET=ON \
    -DARROW_WITH_BROTLI=ON \
    -DARROW_WITH_BZ2=ON \
    -DARROW_WITH_LZ4=ON \
    -DARROW_WITH_SNAPPY=ON \
    -DARROW_WITH_ZLIB=ON \
    -DARROW_WITH_ZSTD=ON \
    -DPARQUET_REQUIRE_ENCRYPTION=ON \
    -DBUILD_SHARED_LIBS=ON \
    ..

echo "------------------ Building Arrow C++ ------------------"

make -j$(nproc)
make install

cd ../../..

# -----------------------------------------------------------------------------
# Build PyArrow Python package
# -----------------------------------------------------------------------------

cd arrow/python

export PYARROW_WITH_COMPUTE=1
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_DATASET=1
export PYARROW_PARALLEL=4
export PYARROW_BUILD_TYPE=release
export PYARROW_BUNDLE_ARROW_CPP_HEADERS=1

echo "------------------ Installing PyArrow ${PYARROW_VERSION} ------------------"

python3.14 -m pip install .

echo "------------------ Verifying PyArrow ------------------"

python3.14 -c "import pyarrow; print('PyArrow version:', pyarrow.__version__)"

cd ../..

# -----------------------------------------------------------------------------
# Clone tokenizers
# -----------------------------------------------------------------------------

echo "------------------ Cloning tokenizers ------------------"

git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}

git checkout ${PACKAGE_VERSION}

cd bindings/python

# -----------------------------------------------------------------------------
# Install tokenizers dependencies
# -----------------------------------------------------------------------------

echo "------------------ Installing tokenizers dependencies ------------------"

python3.14 -m pip install \
    pytest \
    pytest-asyncio \
    setuptools \
    numpy==${NUMPY_VERSION} \
    tiktoken \
    build \
    maturin

# datasets==2.0.0 is intentionally not installed because it is
# incompatible with PyArrow 25.x due to removal of PyExtensionType.
#
# The tokenizers tests that require datasets are explicitly excluded
# below.

# -----------------------------------------------------------------------------
# Verify dependency versions
# -----------------------------------------------------------------------------

echo "------------------ Verifying dependency versions ------------------"

python3.14 -c "import numpy; print('NumPy version:', numpy.__version__)"
python3.14 -c "import pyarrow; print('PyArrow version:', pyarrow.__version__)"

# -----------------------------------------------------------------------------
# Build and install tokenizers
# -----------------------------------------------------------------------------

echo "------------------ Installing tokenizers ------------------"

if ! python3.14 -m pip install . ; then
    echo "------------------${PACKAGE_NAME}:Install_fails-------------------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_Fails"
    exit 1
fi

# -----------------------------------------------------------------------------
# Run tokenizers tests
# -----------------------------------------------------------------------------

echo "------------------ Running tokenizers tests ------------------"

# These tests require the datasets package:
#
#   benches/test_tiktoken.py
#   tests/documentation/test_tutorial_train_from_iterators.py
#
# datasets==2.0.0 is incompatible with the PyArrow 25.x version being built.
#
# Exclude these files using --ignore because pytest -k filtering happens
# after test collection, while these files import datasets during collection.
#
# Also skip the tests that were previously excluded for platform parity.

if ! python3.14 -m pytest \
    --ignore=benches/test_tiktoken.py \
    --ignore=tests/documentation/test_tutorial_train_from_iterators.py \
    -k "not test_continuing_prefix_trainer_mistmatch and not test_gzip"; then

    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------${PACKAGE_NAME}:install_&_test_both_success-------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi