#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyarrow
# Version       : 15.0.1
# Source repo   : https://github.com/apache/arrow.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
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
PACKAGE_DIR=./arrow/python
CURRENT_DIR="${PWD}"
 
# Install necessary dependencies
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openssl-devel cmake openblas openblas-devel

 
echo "Dependencies installed."
 
mkdir dist
export CXX=g++
export CC=gcc
export ARROW_HOME=$(pwd)/dist
export PYARROW_BUNDLE_ARROW_CPP=1
export LD_LIBRARY_PATH=$(pwd)/dist/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$ARROW_HOME:$CMAKE_PREFIX_PATH
 
echo "Cloning the repository..."
git clone $PACKAGE_URL
cd arrow
git checkout $PACKAGE_VERSION
git submodule update --init
echo "Repository cloned and checked out to version $PACKAGE_VERSION."
 
echo "Setting test data paths..."
export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA="${PWD}/testing/data"
 
echo "Applying fixes for nogil placement and rvalue issues..."
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/error.pxi
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/includes/libarrow.pxd
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/lib.pxd
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/includes/libarrow_fs.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/error.pxi
sed -i -E 's/\&\&/\&/g' python/pyarrow/includes/libarrow.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/lib.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/includes/libarrow_fs.pxd
sed -i '/cdef object alloc_c_schema(ArrowSchema\*\* c_schema)/s/ noexcept//' python/pyarrow/types.pxi
sed -i '/cdef object alloc_c_array(ArrowArray\*\* c_array)/s/ noexcept//' python/pyarrow/types.pxi
sed -i '/cdef object alloc_c_stream(ArrowArrayStream\*\* c_stream)/s/ noexcept//' python/pyarrow/types.pxi
echo "Fixes applied."

PYTHON_EXEC=$(which python3)
$PYTHON_EXEC -m pip install -U pip
$PYTHON_EXEC -m pip install -r python/requirements-build.txt
$PYTHON_EXEC -m pip install "Cython<3.1,!=3.0.9" "setuptools>=70.1" wheel numpy==1.26.4 setuptools-scm

NUMPY_INCLUDE=$($PYTHON_EXEC - <<EOF
import numpy; print(numpy.get_include())
EOF
)
 
mkdir cpp/build
cd cpp/build
 
cmake -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
      -DPython3_EXECUTABLE=$PYTHON_EXEC \
      -DPython3_NumPy_INCLUDE_DIRS=$NUMPY_INCLUDE \
      -DCMAKE_INSTALL_LIBDIR=lib64 \
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
      -DBUILD_SHARED_LIBS=ON \
      ..
make -j$(nproc)
make install
cd ../../..
 
cd $PACKAGE_DIR
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_DATASET=1
export PYARROW_PARALLEL=4
export PYARROW_BUILD_TYPE="release"
export PYARROW_BUNDLE_ARROW_CPP_HEADERS=1

version=$(echo "$PACKAGE_VERSION" | sed 's/^apache-arrow-//')
export SETUPTOOLS_SCM_PRETEND_VERSION=$version
export LD_LIBRARY_PATH=${ARROW_HOME}/lib64:${LD_LIBRARY_PATH}
if ! python3 setup.py bdist_wheel --dist-dir="$CURRENT_DIR/" ; then
        echo "------------------$PACKAGE_NAME:wheel_built_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  wheel_built_fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:wheel_built_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Wheel_built_success"
        exit 0
fi
 
# Skipping the tests as most of the tests are parity with x86 also
