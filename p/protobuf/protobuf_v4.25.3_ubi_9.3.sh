#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : protobuf
# Version          : v4.25.3
# Source repo      : https://github.com/protocolbuffers/protobuf
# Tested on   	   : UBI:9.3
# Language         : Python
# Ci-Check     : True
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

set -ex 

PACKAGE_NAME=protobuf
PACKAGE_VERSION=${1:-v4.25.3}
PACKAGE_URL=https://github.com/protocolbuffers/protobuf
PACKAGE_DIR="protobuf"
WORK_DIR=$(pwd)

yum install -y make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel patch python python-devel ninja-build gcc-toolset-13 

PYTHON_VERSION=$(python --version 2>&1 | cut -d ' ' -f 2 | cut -d '.' -f 1,2) 
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export SITE_PACKAGE_PATH="/lib/python${PYTHON_VERSION}/site-packages"
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

pip install --upgrade cmake pip setuptools wheel ninja packaging tox pytest build

#Building abseil-cpp
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"

git clone $ABSEIL_URL -b $ABSEIL_VERSION

echo "------------abseil-cpp cloned--------------"
cd ..

#Setting paths and versions
PREFIX=$SITE_PACKAGE_PATH
ABSEIL_PREFIX=$SOURCE_DIR/local/abseilcpp

export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

#Build libprotobuf
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

SOURCE_DIR=$(pwd)
mkdir -p $SOURCE_DIR/local/libprotobuf
LIBPROTO_INSTALL=$SOURCE_DIR/local/libprotobuf

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
cmake install .

cd ..

#Build protobuf
export PROTOC=$SOURCE_DIR/build/protoc
export LD_LIBRARY_PATH=$WORK_DIR/abseil-cpp/abseilcpp/lib:$(pwd)/build:$LD_LIBRARY_PATH
export LIBRARY_PATH=$(pwd)/build:$LD_LIBRARY_PATH
export LDFLAGS="-L$(pwd)/build"
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

#Apply patch 
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply set_cpp_to_17_v4.25.3.patch

cd python

#Build
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Faced error because of missing comma so adding comma
sed -i 's/CC PYTHONPATH KOKORO_BUILD_ID KOKORO_BUILD_NUMBER/CC, PYTHONPATH, KOKORO_BUILD_ID, KOKORO_BUILD_NUMBER/' tox.ini
## Commenting out because pkg_resources is deprecated (see https://setuptools.pypa.io/en/latest/pkg_resources.html)
sed -i '/python setup.py -q build_py/ s/^/# /' tox.ini

# Run test cases
if !(tox -e py3); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
fi

python setup.py bdist_wheel --cpp_implementation --dist-dir $WORK_DIR
exit 0
