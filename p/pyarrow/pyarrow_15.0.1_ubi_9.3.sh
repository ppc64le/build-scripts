#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyarrow
# Version       : 15.0.1
# Source repo   : https://github.com/apache/arrow.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    :  Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
 
# Variables
PACKAGE_NAME=pyarrow
PACKAGE_VERSION=${1:-apache-arrow-15.0.1}
PACKAGE_URL=https://github.com/apache/arrow.git
PACKAGE_DIR=arrow
 
echo "Installing dependencies..."
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openssl-devel cmake
echo "Dependencies installed."
 
mkdir dist
 
# Set environment variables
export CXX=g++
export CC=gcc
export ARROW_HOME=$(pwd)/dist
export LD_LIBRARY_PATH=$ARROW_HOME/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$ARROW_HOME:$CMAKE_PREFIX_PATH
 
echo "Environment variables set:"
echo "CXX=$CXX"
echo "CC=$CC"
echo "ARROW_HOME=$ARROW_HOME"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo "CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH"
 
echo "Cloning the repository..."
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule update --init
echo "Repository cloned and checked out to version $PACKAGE_VERSION."
 
echo "Setting test data paths..."
export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA="${PWD}/testing/data"
echo "PARQUET_TEST_DATA=$PARQUET_TEST_DATA"
echo "ARROW_TEST_DATA=$ARROW_TEST_DATA"
 
echo "Applying fixes for nogil placement and rvalue issues..."
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/error.pxi
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/includes/libarrow.pxd
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/lib.pxd
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/includes/libarrow_fs.pxd
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/types.pxi
sed -i -E 's/\&\&/\&/g' python/pyarrow/error.pxi
sed -i -E 's/\&\&/\&/g' python/pyarrow/includes/libarrow.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/lib.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/includes/libarrow_fs.pxd
sed -i '/cdef object alloc_c_schema(ArrowSchema\*\* c_schema)/s/ noexcept//' python/pyarrow/types.pxi
sed -i '/cdef object alloc_c_array(ArrowArray\*\* c_array)/s/ noexcept//' python/pyarrow/types.pxi
sed -i '/cdef object alloc_c_stream(ArrowArrayStream\*\* c_stream)/s/ noexcept//' python/pyarrow/types.pxi
echo "Fixes applied."
 
echo "Installing Python dependencies..."
pip install -r python/requirements-build.txt
pip install cython wheel numpy==1.21.2
echo "Python dependencies installed."
 
echo "Preparing for build..."
mkdir cpp/build
cd cpp/build
echo "Current directory: $(pwd)"
 
cmake -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_BUILD_TYPE=Release \
      -DARROW_BUILD_TESTS=ON \
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
      ..
 
echo "Starting build..."
make -j$(nproc)
make install
echo "Build completed successfully."
 
cd ../..
cd python
echo "Current directory: $(pwd)"
 
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_DATASET=1
export PYARROW_PARALLEL=4
export PYARROW_BUILD_TYPE="release"
 
echo "PYARROW_WITH_PARQUET=$PYARROW_WITH_PARQUET"
echo "PYARROW_WITH_DATASET=$PYARROW_WITH_DATASET"
echo "PYARROW_PARALLEL=$PYARROW_PARALLEL"
echo "PYARROW_BUILD_TYPE=$PYARROW_BUILD_TYPE"
 
if ! python3 setup.py bdist_wheel ; then
    echo "------------------$PACKAGE_NAME:wheel_built_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | $(uname -o) | GitHub | Fail | wheel_built_fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:wheel_built_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | $(uname -o) | GitHub | Pass | Wheel_built_success"
    exit 0
fi
 
# Skipping the tests as most of the tests are parity with x86 also