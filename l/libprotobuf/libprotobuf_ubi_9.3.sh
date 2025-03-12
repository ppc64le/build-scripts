#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : libprotobuf
# Version          : v4.25.3
# Source repo      : https://github.com/protocolbuffers/protobuf
# Tested on   	   : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=libprotobuf
PACKAGE_VERSION=${1:-v4.25.3}
PACKAGE_URL=https://github.com/protocolbuffers/protobuf
PACKAGE_DIR="protobuf"
WORK_DIR=$(pwd)

yum install -y make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel gcc-gfortran patch python python-devel ninja-build gcc-toolset-13 

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export SITE_PACKAGE_PATH="/lib/python3.12/site-packages"
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

pip install --upgrade cmake pip setuptools wheel ninja packaging

#Building abseil-cpp
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"
mkdir $WORK_DIR/abseil-prefix
PREFIX=$WORK_DIR/abseil-prefix
mkdir -p $WORK_DIR/local/abseilcpp
abseilcpp=$WORK_DIR/local/abseilcpp

git clone $ABSEIL_URL -b $ABSEIL_VERSION
echo "abseil-cpp build starts"
cd abseil-cpp
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

cp -r  $PREFIX/* $abseilcpp/
cd ..

#create pyproject.toml
wget https://raw.githubusercontent.com/ramnathnayak-ibm/build-scripts/refs/heads/libprotobuf/l/libprotobuf/abseil-cpp/pyproject.toml

#if required create a new folder and build a wheel in that
python3 -m pip wheel -w abseil-cpp -vv --no-build-isolation --no-deps .
pip install *.whl

echo "------------abseil-cpp installed--------------"
cd ..

#Setting paths and versions
PREFIX=$SITE_PACKAGE_PATH
ABSEIL_PREFIX=$PREFIX/abseilcpp/

export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

mkdir -p $(pwd)/local/libprotobuf
LIBPROTO_INSTALL=$(pwd)/local/libprotobuf

#Build libprotobuf
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule update --init --recursive
rm -rf ./third_party/googletest | true
rm -rf ./third_party/abseil-cpp | true

cp -r $WORK_DIR/abseil-cpp ./third_party/

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

#Build
if ! (cmake --install .) ; then
    echo "------------------$PACKAGE_NAME:install_&_test_both_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

cd ..

#create pyproject.toml
wget https://raw.githubusercontent.com/ramnathnayak-ibm/build-scripts/refs/heads/libprotobuf/l/libprotobuf/pyproject.toml

python3 -m pip wheel -w libprotobuf -vv --no-build-isolation --no-deps .



