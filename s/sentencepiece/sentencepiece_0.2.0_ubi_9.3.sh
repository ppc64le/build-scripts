#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : sentencepiece
# Version          : 0.2.0
# Source repo      : https://github.com/google/sentencepiece.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
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


yum install -y make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel patch python python-devel ninja-build gcc-toolset-13  pkg-config

dnf install -y gcc-toolset-13-libatomic-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export SITE_PACKAGE_PATH="/lib/python3.12/site-packages"

SCRIPT_DIR=$(pwd)
PACKAGE_NAME=sentencepiece
PACKAGE_VERSION=${1:-v0.2.0}
PACKAGE_URL=https://github.com/google/sentencepiece.git
PACKAGE_DIR=sentencepiece/python


#building abesil-cpp and libprotobuf 


pip install --upgrade cmake pip setuptools wheel ninja packaging pytest

#Building abseil-cpp
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"
mkdir $SCRIPT_DIR/abseil-prefix
PREFIX=$SCRIPT_DIR/abseil-prefix

git clone $ABSEIL_URL -b $ABSEIL_VERSION
echo "abseil-cpp build starts"
cd abseil-cpp

SOURCE_DIR=$(pwd)

mkdir -p $SOURCE_DIR/local/abseilcpp
abseilcpp=$SOURCE_DIR/local/abseilcpp

mkdir build
cd build

cmake -G Ninja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DBUILD_SHARED_LIBS=ON \
    -DABSL_PROPAGATE_CXX_STD=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
   ..
cmake --build .
cmake --install .

cd $SCRIPT_DIR
cp -r  $PREFIX/* $abseilcpp/

echo "------------abseil-cpp installed--------------"
cd ..

#Setting paths and versions
PREFIX=$SITE_PACKAGE_PATH
ABSEIL_PREFIX=$SOURCE_DIR/local/abseilcpp

export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

#Build libprotobuf
git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v4.25.3

SOURCE_DIR=$(pwd)
mkdir -p $SOURCE_DIR/local/libprotobuf
LIBPROTO_INSTALL=$SOURCE_DIR/local/libprotobuf

git submodule update --init --recursive
rm -rf ./third_party/googletest | true
rm -rf ./third_party/abseil-cpp | true

cp -r $SCRIPT_DIR/abseil-cpp ./third_party/

mkdir build
cd build

cmake -G "Ninja" \
   ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=$C_COMPILER \
    -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
    -DCMAKE_INSTALL_PREFIX=$LIBPROTO_INSTALL \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_LIBUPB=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER="module" \
    -DCMAKE_PREFIX_PATH=$ABSEIL_PREFIX \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..

cmake --build . --verbose

cmake --install .

echo "------------ libprotobuf installed--------------"

####cloning sentencepiece

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export PATH="${SITE_PACKAGE_PATH}/libprotobuf/bin/protoc:${PATH}"
export LD_LIBRARY_PATH="${SITE_PACKAGE_PATH}/libprotobuf/lib64:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${SITE_PACKAGE_PATH}/abseilcpp/lib:${LD_LIBRARY_PATH}"
export CMAKE_PREFIX_PATH="${SITE_PACKAGE_PATH}"

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
cmake -DCMAKE_INSTALL_PREFIX="${HOME}" .. -DSPM_BUILD_TEST=ON -DSPM_ENABLE_TCMALLOC=OFF -DSPM_USE_BUILTIN_PROTOBUF=OFF -DCMAKE_AR=${GCC_AR}
make -j $(nproc)
export PKG_CONFIG_PATH=${VIRTUAL_ENV}/lib/pkgconfig:${VIRTUAL_ENV}/lib64/pkgconfig:${PKG_CONFIG_PATH}
export LD_LIBRARY_PATH=${VIRTUAL_ENV}/lib:${VIRTUAL_ENV}/lib64:${LD_LIBRARY_PATH}
make install

cd ../python
if ! pip install .  ; then
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
