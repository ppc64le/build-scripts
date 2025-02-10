#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : LightGBM
# Version          : 4.2.0
# Source repo      : https://github.com/microsoft/LightGBM.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=LightGBM
PACKAGE_VERSION=${1:-v4.2.0}
PACKAGE_URL=https://github.com/microsoft/LightGBM.git
PACKAGE=LightGBM
PACKAGE_DIR=LightGBM/lightgbm-python

echo "Installing dependencies..."
yum install -y git gcc gcc-c++ cmake make wget openssl-devel bzip2-devel libffi-devel zlib-devel libjpeg-devel gcc-gfortran openblas atlas openblas-devel

echo "Clone the repository..."
git clone $PACKAGE_URL
cd $PACKAGE
git submodule update --init --recursive
echo "checking out package version "
git checkout $PACKAGE_VERSION

echo "install necessary dependency"
pip install scipy

echo "install scikit-learn"
echo "clone scikit repo"
git clone https://github.com/scikit-learn/scikit-learn
echo "cd package name"
cd scikit-learn
echo "checkout package version"
git checkout 1.3.0
echo "update submodule"
git submodule update --init

echo "installing pytest...."
pip install pytest
echo "installing cython.."
pip install cython==0.29.36
echo "installing numpy.."
pip install numpy==1.23.5
echo "installing scipy.."
pip install scipy
echo "installing joblib.."
pip install joblib
echo "installing threadpoolctl.."
pip install threadpoolctl
echo "installing meson-python and ninja.."
pip install meson-python ninja
echo "installing setuptools.."
pip install setuptools==59.8.0 wheel
python setup.py build_ext --inplace
echo "install other necessary dependency"
pip install cloudpickle psutil
echo "install matplotlib"
pip install matplotlib
echo "install pandas"
pip install pandas==1.5.3
echo "install scikit_build_core"
pip install scikit-build-core

echo "installing..."
pip install . --no-build-isolation
echo "back to lightgbm dir"
cd ..

#build pyarrow
echo "Cloning the repository..."
# Clone the repository
git clone https://github.com/apache/arrow.git
cd arrow
git checkout apache-arrow-11.0.0
git submodule update --init
echo "Repository cloned and checked out to version"

echo "Setting test data paths..."
# Set test data paths
export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA="${PWD}/testing/data"
echo "Test data paths set."

echo "Applying fixes for nogil placement and rvalue issues..."
# Apply fixes for nogil placement and rvalue issues
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/error.pxi
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/includes/libarrow.pxd
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/lib.pxd
# Replace rvalue references '&&' with lvalue references '&'
sed -i -E 's/\&\&/\&/g' python/pyarrow/error.pxi
sed -i -E 's/\&\&/\&/g' python/pyarrow/includes/libarrow.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/lib.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/includes/libarrow_fs.pxd
echo "Fixes applied."

echo "Preparing for build..."
# Prepare for build
cd ..
pip install -r arrow/python/requirements-build.txt
pip install -r arrow/python/requirements-test.txt
mkdir dist
export ARROW_HOME=$(pwd)/dist
export LD_LIBRARY_PATH=$ARROW_HOME/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$ARROW_HOME:$CMAKE_PREFIX_PATH
echo "Build preparation completed."

echo "Building Arrow C++ libraries..."
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
echo "executing make command ..."
make -j$(nproc)
echo "make install ..."
make install
echo "Arrow C++ libraries built and installed."

echo "Building PyArrow..."
# Build PyArrow
cd ../..
cd python
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_DATASET=1
export PYARROW_PARALLEL=4
pip install pytest==6.2.5
echo "installing numpy ..."
pip install "numpy<2"
echo "installing other necessary dependency ..."
pip install --upgrade setuptools wheel
pip install wheel hypothesis pytest-lazy-fixture pytz
echo "building package ..."
CMAKE_PREFIX_PATH=$ARROW_HOME python3 setup.py build_ext --inplace

echo "Installing PyArrow Python package..."
# Install the generated Python package
CMAKE_PREFIX_PATH=$ARROW_HOME python3 setup.py install
echo "PyArrow Python package installed."
cd /LightGBM

echo "installing base package ..."
./build-python.sh
echo "lightgbm dir ....."
cd lightgbm-python
#pip install numpy==1.23.5

echo "installing package ..."
if ! (pip install --no-deps .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

echo "run tests  ..."
if !(pytest /LightGBM/tests --cache-clear -p no:hypothesis); then
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
