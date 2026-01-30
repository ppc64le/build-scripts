#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tokenizers
# Version       : v0.21.1
# Source repo   : https://github.com/huggingface/tokenizers
# Tested on     : UBI:9.5
# Language      : C,Python
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Aaruni Aggarwal <aaragga1@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=tokenizers
PACKAGE_VERSION=${1:-v0.21.1}
PACKAGE_URL=https://github.com/huggingface/tokenizers
PACKAGE_DIR=tokenizers/bindings/python

yum install -y wget gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran git make python python-devel python-pip  openssl-devel cmake unzip rust cargo

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

#Install arrow as it required to build for tokenizers
echo "Cloning and installing..."
git clone https://github.com/apache/arrow
cd arrow/
git checkout apache-arrow-19.0.1

git submodule update --init
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

mkdir dist
export CXX=g++
export CC=gcc
export ARROW_HOME=$(pwd)/dist
export PYARROW_BUNDLE_ARROW_CPP=1
export LD_LIBRARY_PATH=$(pwd)/dist/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$ARROW_HOME/lib64/cmake:$CMAKE_PREFIX_PATH

echo "installing python dependencies..."
pip install -r python/requirements-build.txt
pip install cython wheel six setuptools numpy

mkdir cpp/build
cd cpp/build

echo "cmake installing..."
cmake -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
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
echo "installing..."
make -j$(nproc)
make install
cd ../../..

cd arrow/python/
export PYARROW_WITH_COMPUTE=1
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_DATASET=1
export PYARROW_PARALLEL=4
export PYARROW_BUILD_TYPE="release"
export PYARROW_BUNDLE_ARROW_CPP_HEADERS=1

echo "installing..."
pip install .
cd ../..

echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cd bindings/python/

echo "installing python dependencies..."
pip install pytest setuptools datasets==2.0.0 numpy tiktoken build maturin

echo "installing..."
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Skipped these tests as these tests were parity with intel
if ! pytest -k "not(test_continuing_prefix_trainer_mismatch or test_gzip or test_tiktoken or test_datasets)"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
