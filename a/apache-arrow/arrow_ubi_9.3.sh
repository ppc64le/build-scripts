#!/usr/bin/env bash
# -----------------------------------------------------------------
#
# Package	     : arrow
# Version	     : apache-arrow-19.0.1
# Source repo	 : https://github.com/apache/arrow
# Tested on	     : UBI 9.3
# Language       : C++
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer	 : Onkar Kubal <onkar.kubal@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
PACKAGE_NAME=arrow
SCRIPT_PACKAGE_VERSION=main
PACKAGE_VERSION=apache-arrow-19.0.1
PACKAGE_URL=https://github.com/apache/arrow
SCRIPT_PATH=$(dirname $(realpath $0))
BUILD_HOME=$(pwd)


# Update and install dependencies
yum update -y && yum install -y wget git cmake clang ninja-build bzip2 gcc-toolset-13
cd $BUILD_HOME

# Install gcc 13
source /opt/rh/gcc-toolset-13/enable
gcc --version
cd $BUILD_HOME

# echo "alias python=python3" >> .bashrc
# source ~/.bashrc


# Download arrow
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git pull -f
git checkout ${PACKAGE_VERSION}

git submodule update --init --recursive
export PARQUET_TEST_DATA=$BUILD_HOME/arrow/cpp/submodules/parquet-testing/data
export ARROW_TEST_DATA=$BUILD_HOME/arrow/cpp/../testing/data

echo $PARQUET_TEST_DATA
echo $ARROW_TEST_DATA
# Build Arrow C++ library
mkdir cpp/build
cd cpp/build
cmake .. \
  -DARROW_WITH_SNAPPY=ON \
  -DARROW_WITH_ZLIB=ON \
  -DARROW_WITH_LZ4=ON \
  -DARROW_WITH_ZSTD=ON \
  -DARROW_PARQUET=ON \
  -DARROW_CSV=ON \
  -DARROW_DATASET=ON \
  -DARROW_BUILD_TESTS=ON \
  -DARROW_BUILD_UTILITIES=OFF \
  -DARROW_BUILD_SHARED=ON \
  -DARROW_PYTHON=ON \
  -DPython3_EXECUTABLE=/usr/bin/python3 \
  -DARROW_JEMALLOC=OFF \
  -DCMAKE_BUILD_TYPE=Release

if ! cmake --build . ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

cmake --install .

if ! ctest -j$(nproc) --output-on-failure ; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi