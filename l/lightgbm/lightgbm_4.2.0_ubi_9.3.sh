#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : LightGBM
# Version          : 4.2.0
# Source repo      : https://github.com/microsoft/LightGBM.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vaibhav Bhadade <vaibhav.bhadade@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

set -ex 
# Variables
PACKAGE_NAME=LightGBM
PACKAGE_VERSION=${1:-v4.2.0}
PACKAGE_URL=https://github.com/microsoft/LightGBM.git
PACKAGE=LightGBM
PACKAGE_DIR=LightGBM/lightgbm-python
CURRENT_DIR=$(pwd)

echo "Installing dependencies..."
yum install -y git gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ cmake make wget openssl-devel bzip2-devel libffi-devel zlib-devel libjpeg-devel gcc-gfortran openblas atlas openblas-devel python3 python3-devel python3-pip glibc-static

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++

echo "Installing openmpi"
wget https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.6.tar.gz
tar -xvf openmpi-5.0.6.tar.gz
cd openmpi-5.0.6
mkdir prefix
export PREFIX=$(pwd)/prefix

#Set environment variables for OpenMPI
export LIBRARY_PATH="/usr/lib64"

#Configure and build OpenMPI
./configure --prefix=$PREFIX \
    --disable-dependency-tracking \
    --disable-shared \
    --enable-static \
    LDFLAGS="-static"
echo "installing openmpi"
make -j$(nproc)
make install

#Set OpenMPI paths
export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH

#Navigate back to the root directory
cd $CURRENT_DIR

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
pip install scipy==1.13.1
echo "installing joblib.."
pip install joblib
echo "installing threadpoolctl.."
pip install threadpoolctl
echo "installing meson-python and ninja.."
pip install meson-python ninja
echo "installing setuptools.."
pip install setuptools==59.8.0 wheel
echo "install other necessary dependency"
pip install cloudpickle psutil
echo "install matplotlib"
pip install matplotlib
echo "install pandas"
pip install pandas==1.5.3
echo "install scikit_build_core"
pip install scikit-build-core

cd ..

#build pyarrow
echo "Cloning Arrow repository..."
git clone https://github.com/apache/arrow.git
cd arrow
git checkout apache-arrow-11.0.0
git submodule update --init

echo "Setting test data paths..."
export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA="${PWD}/testing/data"

echo "Applying fixes for nogil placement and rvalue issues..."
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/error.pxi
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/includes/libarrow.pxd
sed -i -E 's/(nogil)(.*)(except[^:]*)/\2\3 \1/' python/pyarrow/lib.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/error.pxi
sed -i -E 's/\&\&/\&/g' python/pyarrow/includes/libarrow.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/lib.pxd
sed -i -E 's/\&\&/\&/g' python/pyarrow/includes/libarrow_fs.pxd

echo "Installing Python dependencies..."
cd ..
pip install -r arrow/python/requirements-build.txt
pip install -r arrow/python/requirements-test.txt
pip install pytest==6.2.5 numpy==1.23.5
pip install --upgrade setuptools wheel
pip install hypothesis pytest-lazy-fixture pytz

echo "Setting build environment..."
mkdir -p dist
export ARROW_HOME=$(pwd)/dist
export LD_LIBRARY_PATH=$ARROW_HOME/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$ARROW_HOME:$CMAKE_PREFIX_PATH
export Arrow_DIR=$ARROW_HOME/lib/cmake/Arrow  # crucial fix

echo "Building Arrow C++ libraries..."
mkdir -p arrow/cpp/build
cd arrow/cpp/build
cmake -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
    -DCMAKE_INSTALL_LIBDIR=lib \
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
    ..
make -j$(nproc)
make install

echo "Arrow C++ libraries built and installed."

echo "Building PyArrow..."
cd ../../python

export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_DATASET=1
export PYARROW_PARALLEL=4
export PYARROW_BUNDLE_ARROW_CPP=1
export PYARROW_BUNDLE_ARROW_CPP_HEADERS=1
export CMAKE_PREFIX_PATH=$ARROW_HOME
export Arrow_DIR=$ARROW_HOME/lib/cmake/Arrow
export LD_LIBRARY_PATH=$ARROW_HOME/lib:$LD_LIBRARY_PATH

python3 setup.py build_ext --inplace
python3 setup.py install
echo " PyArrow built and installed successfully."

cd ../..
cd $CURRENT_DIR
#installing scikit-learn
cd $PACKAGE/scikit-learn
echo "installing scikit-learn..."
python3 setup.py build_ext --inplace
pip install . --no-build-isolation
echo "back to lightgbm dir"
cd ../

echo "installing base package and setting mpi flags ..."
./build-python.sh
echo "set mpi library paths"
#Set OpenMPI paths
export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH

echo "lightgbm dir ....."
cd lightgbm-python

echo "Running build with MPI condition..."
python3 -m build --wheel --config-setting=cmake.define.USE_MPI=ON --outdir="$CURRENT_DIR"

echo "installing package ..."
if ! (pip install --no-deps .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

echo "run tests  ..."
if !(pytest ../tests --cache-clear -p no:hypothesis); then
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
