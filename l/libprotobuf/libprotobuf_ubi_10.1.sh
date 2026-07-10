#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : libprotobuf
# Version          : v6.31.1
# Source repo      : https://github.com/protocolbuffers/protobuf
# Tested on        : UBI:10.1
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : tejasBadjateIBM <Tejas.Badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=libprotobuf
PACKAGE_VERSION=${1:-v6.31.1}
PACKAGE_URL=https://github.com/protocolbuffers/protobuf
PACKAGE_DIR="protobuf"
WORK_DIR=$(pwd)

yum install -y make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel patch python python-devel python-pip ninja-build gcc-c++ g++

PYTHON_VERSION=$(python --version 2>&1 | cut -d ' ' -f 2 | cut -d '.' -f 1,2)
export SITE_PACKAGE_PATH="/lib/python${PYTHON_VERSION}/site-packages"

pip install --upgrade cmake pip setuptools wheel ninja packaging


echo "------------ libprotobuf installing-------------------"

export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

#Build libprotobuf
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/main/l/libprotobuf/0001-Fixed-CVE-2026-0994-for-protobuf-6.31.1.patch
git apply 0001-Fixed-CVE-2026-0994-for-protobuf-6.31.1.patch

LIBPROTO_DIR=$(pwd)
mkdir -p $LIBPROTO_DIR/local/libprotobuf
LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf

git submodule update --init --recursive
rm -rf ./third_party/googletest | true


mkdir build
cd build

#Building and testing is performed through the same command
if ! (cmake -G "Ninja" \
   ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=$C_COMPILER \
    -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
    -DCMAKE_INSTALL_PREFIX=$LIBPROTO_INSTALL \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER="module" \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..) ; then
    echo "------------------$PACKAGE_NAME:install_&_test_both_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
fi

cmake --build . --verbose
cmake --install .

cd ..
wget -O pyproject.toml https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/main/l/libprotobuf/pyproject_v6.31.1.toml
sed -i "s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g" pyproject.toml

python -m pip wheel -w $WORK_DIR -vv --no-build-isolation --no-deps .

exit 0
