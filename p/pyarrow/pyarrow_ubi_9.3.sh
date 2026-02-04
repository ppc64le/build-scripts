#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyarrow
# Version       : 11.0.0
# Source repo : https://github.com/apache/arrow.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
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
PACKAGE_VERSION=${1:-apache-arrow-11.0.0}
PACKAGE_URL=https://github.com/apache/arrow.git
PACKAGE_DIR=./arrow/python
CURRENT_DIR="${PWD}"

yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openssl-devel cmake

echo "Dependencies installed."
mkdir dist
export CXX=g++
export CC=gcc
export ARROW_HOME=$(pwd)/dist
export PYARROW_BUNDLE_ARROW_CPP=1
export LD_LIBRARY_PATH=$ARROW_HOME/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$ARROW_HOME:$CMAKE_PREFIX_PATH

echo "-----------------boost_cpp installing-----------------------"

git clone https://github.com/boostorg/boost
cd boost
git checkout boost-1.81.0
git submodule update --init

mkdir Boost_prefix
export BOOST_PREFIX=$(pwd)/Boost_prefix

INCLUDE_PATH="${BOOST_PREFIX}/include"
LIBRARY_PATH="${BOOST_PREFIX}/lib"

export CC=$(which gcc)
export CXX=$(which g++)
export target_platform=$(uname)-$(uname -m)
CXXFLAGS="${CXXFLAGS} -fPIC"
TOOLSET=gcc

 # http://www.boost.org/build/doc/html/bbv2/tasks/crosscompile.html
cat <<EOF > tools/build/example/site-config.jam
using ${TOOLSET} : : ${CXX} ;
EOF

LINKFLAGS="${LINKFLAGS} -L${LIBRARY_PATH}"

ADDRESS_MODEL=64
ARCHITECTURE=power
ABI="sysv"
BINARY_FORMAT="elf"

CXXFLAGS="$(echo ${CXXFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' | sed 's/ -mtune=[^ ]*//g')" \
CFLAGS="$(echo ${CFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' | sed 's/ -mtune=[^ ]*//g')" \
CXX=${CXX_FOR_BUILD:-${CXX}} \
CC=${CC_FOR_BUILD:-${CC}} \
./bootstrap.sh \
  --prefix="${BOOST_PREFIX}" \
  --without-libraries=python \
  --with-toolset=${TOOLSET} \
  --with-icu="${BOOST_PREFIX}" || (cat bootstrap.log; exit 1)

CPU_COUNT=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)
export CPU_COUNT

echo " Building and installing Boost...."
./b2 -q \
    variant=release \
    address-model="${ADDRESS_MODEL}" \
    architecture="${ARCHITECTURE}" \
    binary-format="${BINARY_FORMAT}" \
    abi="${ABI}" \
    debug-symbols=off \
    threading=multi \
    runtime-link=shared \
    link=shared \
    toolset=${TOOLSET} \
    include="${INCLUDE_PATH}" \
    cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
    linkflags="${LINKFLAGS}" \
    --layout=system \
    -j"${CPU_COUNT}" \
    install


# Remove Python headers as we don't build Boost.Python.
rm "${BOOST_PREFIX}/include/boost/python.hpp"
rm -r "${BOOST_PREFIX}/include/boost/python"
cd $CURRENT_DIR

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
echo "Fixes applied."

pip install -r python/requirements-build.txt
pip install "cython<3.0" wheel

echo "Preparing for build..."
export BOOST_ROOT=${BOOST_PREFIX}
export CMAKE_PREFIX_PATH=$ARROW_HOME:$BOOST_PREFIX:$CMAKE_PREFIX_PATH

mkdir cpp/build
cd cpp/build

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
      -DBoost_DIR=${BOOST_PREFIX} \
      -DBoost_INCLUDE_DIR=${BOOST_PREFIX}/include/ \
      -DARROW_WITH_ZLIB=ON \
      -DARROW_WITH_ZSTD=ON \
      -DPARQUET_REQUIRE_ENCRYPTION=ON \
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

#To get proper wheel naming
version=$(echo "$PACKAGE_VERSION" | sed 's/^apache-arrow-//')
export SETUPTOOLS_SCM_PRETEND_VERSION=$version

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
