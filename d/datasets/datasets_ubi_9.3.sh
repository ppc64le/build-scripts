#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : datasets
# Version       : 2.19.1
# Source repo   : https://github.com/huggingface/datasets.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=datasets
PACKAGE_VERSION=${1:-2.19.1}
PACKAGE_URL=https://github.com/huggingface/datasets.git

# Install dependencies and tools.
yum install -y git gcc g++ gcc-c++ gfortran wget patch pkg-config zip unzip cmake gcc-gfortran make python-devel openssl-devel

#installing pyarrow
git clone https://github.com/apache/arrow.git
cd arrow
git checkout apache-arrow-16.1.0
 
git submodule update --init --recursive
export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA="${PWD}/testing/data"

# Build Arrow C++ library  
cd cpp
mkdir build
cd build
export ARROW_HOME=/repos/dist
export LD_LIBRARY_PATH=$ARROW_HOME/lib:$LD_LIBRARY_PATH
	
cmake .. \
  -DARROW_WITH_SNAPPY=ON \
  -DARROW_WITH_ZLIB=ON \
  -DARROW_WITH_LZ4=ON \
  -DARROW_WITH_ZSTD=ON \
  -DARROW_PARQUET=ON \
  -DARROW_CSV=ON \
  -DARROW_DATASET=ON \
  -DARROW_BUILD_TESTS=OFF \
  -DARROW_BUILD_UTILITIES=OFF \
  -DARROW_BUILD_SHARED=ON \
  -DARROW_PYTHON=ON \
  -DPython3_EXECUTABLE=/usr/bin/python3 \
  -DARROW_JEMALLOC=OFF \
  -DCMAKE_BUILD_TYPE=Release
make -j4
make install

cd ../../python/
PYTHONPATH=$ARROW_HOME/lib/python3.9/site-packages:$PYTHONPATH
pip install -r requirements-test.txt
pip install Cython==3.0.8 numpy
CMAKE_PREFIX_PATH=/repos/dist python3 setup.py install
cd ../..

#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#installing all dependencies
pip install .

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
