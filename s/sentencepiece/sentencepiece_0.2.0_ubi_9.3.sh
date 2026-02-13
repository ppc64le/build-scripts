#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : sentencepiece
# Version          : 0.2.0
# Source repo      : https://github.com/google/sentencepiece.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

set -ex

PACKAGE_NAME=sentencepiece
PACKAGE_VERSION=${1:-v0.2.0}
PACKAGE_URL=https://github.com/google/sentencepiece.git
PACKAGE_DIR=sentencepiece/python

yum install -y make libtool git wget tar xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel patch python python-devel ninja-build gcc-toolset-13 gcc gcc-c++ pkg-config

dnf install -y gcc-toolset-13-libatomic-devel

export CC=gcc
export CXX=g++
export FC=gfortran
# command -v g++
gcc --version
g++ --version

PYTHON_VERSION=python$(python --version 2>&1 | cut -d ' ' -f 2 | cut -d '.' -f 1,2)

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export SITE_PACKAGE_PATH="/lib/${PYTHON_VERSION}/site-packages"
SCRIPT_DIR=$(pwd)

#Building abesil-cpp,libprotobuf and protobuf 

pip install --upgrade pip setuptools wheel ninja packaging pytest 

# cmake installing from source 
echo " -------------------------- Cmake Installing -------------------------- " 

wget https://cmake.org/files/v3.28/cmake-3.28.0.tar.gz
tar -zxvf cmake-3.28.0.tar.gz
cd cmake-3.28.0
./bootstrap
make
make install

echo " -------------------------- Cmake Successfully Installed -------------------------- " 

cd $SCRIPT_DIR

#Build libprotobuf
echo " -------------------------- Libprotobuf Installing -------------------------- "

git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v4.25.8

LIBPROTO_DIR=$(pwd)
mkdir -p $LIBPROTO_DIR/local/libprotobuf
LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf

git submodule update --init --recursive
rm -rf ./third_party/googletest | true

mkdir build
cd build

cmake -G "Ninja" \
   ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=$CC \
    -DCMAKE_CXX_COMPILER=$CXX \
    -DCMAKE_INSTALL_PREFIX=$LIBPROTO_INSTALL \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_LIBUPB=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER="module" \
    -DCMAKE_PREFIX_PATH=$ABSEIL_CPP \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..

cmake --build . --verbose
cmake --install .

cd ..

#Build protobuf
export PROTOC=$LIBPROTO_INSTALL/bin/protoc  # CHANGED: Use installed path
export LD_LIBRARY_PATH=$LIBPROTO_INSTALL/lib:$LD_LIBRARY_PATH  # CHANGED: Use installed path
export LIBRARY_PATH=$LIBPROTO_INSTALL/lib:$LIBRARY_PATH  # CHANGED: Use installed path
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

#Apply patch 
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply set_cpp_to_17_v4.25.3.patch

cd python
pip install .

echo " -------------------------- libprotobuf and  protobuf installed -------------------------- "

cd  $SCRIPT_DIR

#Building sentencepiece
echo " -------------------------- Sentencepiece Installing -------------------------- "

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export PATH="$LIBPROTO_INSTALL/bin:${PATH}"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib:${LD_LIBRARY_PATH}"
export CMAKE_PREFIX_PATH="$LIBPROTO_INSTALL"  # ADDED: Let CMake find protobuf/abseil

export GCC_AR="${GCC_HOME}/bin/ar"
mkdir -p ${SCRIPT_DIR}/custom_libs
ln -s /usr/lib64/libatomic.so.1 ${SCRIPT_DIR}/custom_libs/libatomic.so
export LD_LIBRARY_PATH="${SCRIPT_DIR}/custom_libs:${LD_LIBRARY_PATH}"

ARCH=`uname -p`
if [[ "${ARCH}" == 'ppc64le' ]]; then
    ARCH_SO_NAME="powerpc64le"
    export LDFLAGS="${LDFLAGS} -L${VIRTUAL_ENV}/lib -L${SCRIPT_DIR}/custom_libs"
else
    ARCH_SO_NAME=${ARCH}
fi

PAGE_SIZE=`getconf PAGE_SIZE`
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX="${HOME}" .. -DSPM_BUILD_TEST=ON -DSPM_ENABLE_TCMALLOC=OFF \
    -DSPM_USE_BUILTIN_PROTOBUF=OFF -DCMAKE_AR=${GCC_AR} \
    -DSPM_USE_BUILTIN_PROTOBUF=ON
make -j $(nproc)
make install
cd ../python

if ! pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest  ; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME "
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME "
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Pass |  Test_Success"
	exit 0
fi
