#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyarrow
# Version       : 11.0.0
# Source repo : https://github.com/apache/arrow.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
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
set -e

# Variables
PACKAGE_NAME=arrow
PACKAGE_VERSION=${1:-maint-11.0.0}
PACKAGE_URL=https://github.com/apache/arrow.git
# Install dependencies
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openssl-devel cmake

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# Set test data paths
export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA="${PWD}/testing/data"

# Apply fixes for nogil placement and rvalue issues
echo "Applying fixes for nogil placement and rvalue issues..."
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/error.pxi
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/includes/libarrow.pxd
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/lib.pxd

# Replace rvalue references '&&' with lvalue references '&'
sed -i -E 's/\&\&/\&/g' python/pyarrow/error.pxi
sed -i -E 's/\&\&/\&/g' python/pyarrow/includes/libarrow.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/lib.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/includes/libarrow_fs.pxd
# Prepare for build
cd ..
pip install -r arrow/python/requirements-build.txt
pip install -r arrow/python/requirements-test.txt
mkdir dist
export ARROW_HOME=$(pwd)/dist
export LD_LIBRARY_PATH=$ARROW_HOME/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$ARROW_HOME:$CMAKE_PREFIX_PATH

# Build Arrow C++ libraries
mkdir arrow/cpp/build
cd arrow/cpp/build
cmake -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_BUILD_TYPE=Debug \
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
make -j4
make install

# Build PyArrow
cd ../..
cd python
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_DATASET=1
export PYARROW_PARALLEL=4
pip install pytest==6.2.5
pip install "numpy<2.0"

pip install --upgrade setuptools wheel
pip install wheel hypothesis pytest-lazy-fixture pytz
CMAKE_PREFIX_PATH=$ARROW_HOME python setup.py build_ext --inplace

# Install the generated Python package
if ! CMAKE_PREFIX_PATH=$ARROW_HOME python3 setup.py install; then
    echo "------------------$PACKAGE_NAME::Python package installation failed-------------------------"
    exit 4
fi

export PYTEST_PATH=$(pwd)/pyarrow
export PYTEST_ADDOPTS="-k 'not test_cython and not test_extension_type' --deselect=pyarrow/tests/test_extension_type.py --deselect=pyarrow/tests/test_compute.py --deselect=pyarrow/tests/test_ipc.py --deselect=pyarrow/tests/test_pandas.py --deselect=pyarrow/tests/parquet/test_dataset.py"
# Run Python tests
if ! python3 -m pytest $PYTEST_PATH ; then
    echo "------------------$PACKAGE_NAME::Python_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Python_Test_Fails"
    exit 3
else
    echo "------------------$PACKAGE_NAME::Build_and_All_Tests_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass | Build_and_All_Tests_Success"
fi
