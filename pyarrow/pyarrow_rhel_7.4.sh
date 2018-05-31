# ----------------------------------------------------------------------------
#
# Package       : pyArrow
# Version       : 0.9.0
# Source repo   : https://github.com/apache/arrow
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install required dependencies
sudo yum update -y
sudo yum install -y wget gcc-c++ make python-devel git python-virtualenv boost-devel flex bison libcurl-devel zlib-devel which

#Build cmake from source as a newer version is required
cd /tmp
wget https://cmake.org/files/v3.10/cmake-3.10.2.tar.gz
tar -zxvf cmake-3.10.2.tar.gz
cd cmake-3.10.2
./bootstrap --system-curl
make
sudo make install
export PATH=/usr/local/bin:$PATH

cd $HOME

#Environment setup and build
virtualenv pyarrow
source ./pyarrow/bin/activate
pip install six numpy cython pytest futures
pip install --upgrade pip

mkdir repos
cd repos
git clone https://github.com/apache/arrow.git
git clone https://github.com/apache/parquet-cpp.git

mkdir -p dist/lib

export ARROW_BUILD_TYPE=release
export ARROW_HOME=$(pwd)/dist
export PARQUET_HOME=$(pwd)/dist
export LD_LIBRARY_PATH=$(pwd)/dist/lib64:$LD_LIBRARY_PATH

#Build and install Arrow C++ libraries
mkdir arrow/cpp/build
pushd arrow/cpp/build

cmake -DCMAKE_BUILD_TYPE=$ARROW_BUILD_TYPE \
      -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
      -DARROW_PYTHON=on \
      -DARROW_BUILD_TESTS=OFF \
      ..
make -j4
sudo make install
popd

#Build and install Apache Parquet libraries
mkdir parquet-cpp/build
pushd parquet-cpp/build

cmake -DCMAKE_BUILD_TYPE=$ARROW_BUILD_TYPE \
      -DCMAKE_INSTALL_PREFIX=$PARQUET_HOME \
      -DPARQUET_BUILD_BENCHMARKS=off \
      -DPARQUET_BUILD_EXECUTABLES=off \
      -DPARQUET_BUILD_TESTS=off \
      ..

make -j4
sudo make install
popd

#Build dependent pandas package (required for running the pyarrow tests)
git clone https://github.com/pandas-dev/pandas
pushd pandas
python setup.py develop
popd

#Build pyarrow
ln -s $(pwd)/dist/lib64/libarrow_python.so $(pwd)/dist/lib/libarrow_python.so
pushd arrow/python
python setup.py build_ext --build-type=$ARROW_BUILD_TYPE --with-parquet --inplace

#Run the pyarrow unit tests
py.test pyarrow
popd
