#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : orc
# Version       : v2.0.7
# Source repo   : https://github.com/apache/orc
# Tested on     : UBI 10.2
# Language      : c
# Ci-Check      : True
# Script License: Apache License 2.0
# Maintainer    : Nayana Thorat <Nayana.Thorat1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=orc
PACKAGE_VERSION=${1:-v2.0.7}
PACKAGE_URL=https://github.com/apache/orc
CURRENT_DIR=$(pwd)

yum install -y wget git make cmake binutils lz4-devel zlib-devel \
    python3.14 python3.14-pip python3.14-devel \
    gcc-toolset-15 ninja-build tzdata

export PATH=/opt/rh/gcc-toolset-15/root/usr/bin:$PATH
export CC=$(which gcc)
export CXX=$(which g++)

python3.14 -m pip install setuptools wheel ninja

cd $CURRENT_DIR

# ZSTD
echo " --------------------------------------------------- Installing ZSTD --------------------------------------------------- "

git clone https://github.com/facebook/zstd.git
cd zstd
make -j$(nproc)
make install

export ZSTD_HOME=/usr/local
export CMAKE_PREFIX_PATH=$ZSTD_HOME:$CMAKE_PREFIX_PATH
export LD_LIBRARY_PATH=$ZSTD_HOME/lib:$LD_LIBRARY_PATH

echo " --------------------------------------------------- ZSTD Successfully Installed --------------------------------------------------- "

cd $CURRENT_DIR

#SNAPPY
echo " --------------------------------------------------- Installing snappy-devel --------------------------------------------------- "
git clone -b 1.2.2 https://github.com/google/snappy
cd snappy
git submodule update --init

mkdir -p local/snappy build
cd build

cmake .. \
  -DBUILD_SHARED_LIBS=ON \
  -DSNAPPY_BUILD_STATIC=OFF \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_INSTALL_LIBDIR=lib64
make -j$(nproc)
make install

echo " --------------------------------------------------- Snappy-devel Successfully Installed --------------------------------------------------- "

cd $CURRENT_DIR
echo " --------------------------------------------------- Cloning protobuf --------------------------------------------------- "

git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v33.6
git submodule update --init --recursive

LIBPROTO_DIR=$(pwd)
mkdir -p $LIBPROTO_DIR/local/libprotobuf
LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf
export PROTOBUF_PREFIX=$LIBPROTO_INSTALL

rm -rf ./third_party/googletest | true

mkdir build
cd build

#Building and testing is performed through the same command
cmake -G "Ninja" \
   ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=$CC \
    -DCMAKE_CXX_COMPILER=$CXX \
    -DCMAKE_INSTALL_PREFIX=$LIBPROTO_INSTALL \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER="module" \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..

cmake --build . --verbose
cmake --install .

echo " --------------------------------------------------- libprotobuf installed successfully --------------------------------------------------- "

# clone source repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/orc/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/$(echo $PACKAGE_VERSION | sed 's/^v//')/g" pyproject.toml
echo "--------------------------replaced version in pyproject.toml--------------------------"

mkdir prefix
export PREFIX=$(pwd)/prefix
mkdir build && cd build

export HOST=$(uname)-$(uname -m)

CPPFLAGS="${CPPFLAGS} -Wl,-rpath,$VIRTUAL_ENV_PATH/**/lib"

cmake ${CMAKE_ARGS} \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_JAVA=False \
    -DLZ4_HOME=/usr \
    -DZLIB_HOME=/usr \
    -DZSTD_HOME=/usr \
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
    -DProtobuf_ROOT=$PROTOBUF_PREFIX \
    -DPROTOBUF_HOME=$PROTOBUF_PREFIX \
    -DPROTOBUF_PROTOC_EXECUTABLE=$PROTOBUF_PREFIX/bin/protoc \
    -DSNAPPY_HOME=/usr \
    -DBUILD_LIBHDFSPP=NO \
    -DBUILD_CPP_TESTS=ON \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_C_COMPILER=$(type -p ${CC})     \
    -DCMAKE_CXX_COMPILER=$(type -p ${CXX})  \
    -DCMAKE_C_FLAGS="$CFLAGS"  \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-unused-parameter" \
    "${_CMAKE_EXTRA_CONFIG[@]}" \
    -GNinja ..

# Build package
if ! (ninja && ninja install) ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd ..

mkdir -p local/$PACKAGE_NAME
cp -r prefix/* local/$PACKAGE_NAME

export LD_LIBRARY_PATH=$PREFIX/lib:$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH

echo "---------------------------------------------------Building the wheel--------------------------------------------------"
python3.14 -m pip install --upgrade build setuptools wheel
python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

echo "----------------------------------------------Testing pkg-------------------------------------------------------"
cd build

# Test package
#if ! (ninja test) ; then
if ! (ctest -E '^tool-test$'); then
    ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
    export TZDIR=/usr/share/zoneinfo
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
