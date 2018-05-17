# ----------------------------------------------------------------------------
#
# Package	: xgboost
# Version	: 0.71
# Source repo	: https://github.com/dmlc/xgboost
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Following section builds googletest. If it's already available,
# entire section can be commented.

# Install dependencies.
apt-get update -y
apt-get install -y cmake software-properties-common curl \
    build-essential git

apt-add-repository -y "ppa:ubuntu-toolchain-r/test"
curl -sSL "http://llvm.org/apt/llvm-snapshot.gpg.key" | apt-key add -
echo "deb http://llvm.org/apt/precise/ llvm-toolchain-precise-3.7 main" | tee -a /etc/apt/sources.list > /dev/null
apt-get -yq --no-install-suggests --no-install-recommends install \
    gcc-4.9 g++-4.9 valgrind

# Set build related environment variables.
export GTEST_TARGET=googletest
export SHARED_LIB=OFF
export STATIC_LIB=ON
export CMAKE_PKG=OFF
export BUILD_TYPE=debug
export VERBOSE_MAKE=true
export CXX=g++
export CC=gcc
if [ "$CXX" = "g++" ]; then export CXX="g++-4.9" CC="gcc-4.9"; fi
if [ "$CXX" = "clang++" ] && [ "$TRAVIS_OS_NAME" = "linux" ]; then export CXX="clang++-3.7" CC="clang-3.7"; fi

# Build and test googletest.
git clone https://github.com/google/googletest.git
cd googletest
mkdir build && cd build
cmake .. && make && make install
#
# End section: build googletest.

# Build and test xgboost with GPU support.
cd

apt-get update -y
apt-get install -y wget git cmake python python-dev python-nose \
    python-setuptools python-numpy python-sklearn liblapack-dev
easy_install pandas graphviz

git clone --recursive https://github.com/dmlc/xgboost
cd xgboost && mkdir build && cd build
cmake .. -DUSE_CUDA=ON -DUSE_NCCL=ON -DCMAKE_BUILD_TYPE=Release
make -j
cd ..
cp build/librabit.a rabit/lib
cd python-package
python setup.py install
cd ..
nosetests tests/python-gpu
