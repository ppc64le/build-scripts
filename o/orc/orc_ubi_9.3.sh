#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : orc
# Version       : v2.0.3
# Source repo   : https://github.com/apache/orc
# Tested on     : UBI 9.3
# Language      : c
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
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
PACKAGE_VERSION=${1:-v2.0.3}
PACKAGE_URL=https://github.com/apache/orc
CURRENT_DIR=$(pwd)

# Set environment variables
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

echo " --------------------------------------------------- Installing dependencies --------------------------------------------------- "
yum install -y wget git make cmake binutils lz4-devel zlib-devel \
    python3 python3-pip python3-devel \
    gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-gcc-c++ \
    ninja-build

python3 -m pip install --upgrade pip
python3 -m pip install setuptools wheel ninja

export CC=$(which gcc)
export CXX=$(which g++)
export GCC=$CC
export GXX=$CXX

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

# Building abseil-cpp which is a dependency for libprotobuf
echo " --------------------------------------------------- Cloning abseil-cpp --------------------------------------------------- "

# Set ABSEIL_VERSION and ABSEIL_URL
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"

git clone $ABSEIL_URL -b $ABSEIL_VERSION

echo " --------------------------------------------------- Abseil-cpp installed successfully --------------------------------------------------- "

# Building libprotobuf which is a dependency for orc
cd $CURRENT_DIR
mkdir -p $CURRENT_DIR/local/libprotobuf
LIBPROTO_INSTALL=$CURRENT_DIR/local/libprotobuf

echo " --------------------------------------------------- Cloning protobuf --------------------------------------------------- "

git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v4.25.8
git submodule update --init --recursive
rm -rf ./third_party/googletest | true
rm -rf ./third_party/abseil-cpp | true
cp -r $CURRENT_DIR/abseil-cpp ./third_party/

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
    -DCMAKE_PREFIX_PATH=$ABSEIL_PREFIX \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..

cmake --build . --verbose
cmake --install .

cd $CURRENT_DIR
export PATH=$LIBPROTO_INSTALL/bin:$PATH
protoc --version

echo " --------------------------------------------------- libprotobuf installed successfully --------------------------------------------------- "

export LD_LIBRARY_PATH=$CURRENT_DIR//local/abseilcpp/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$CURRENT_DIR//local/abseilcpp:$CMAKE_PREFIX_PATH
export PROTOBUF_PREFIX=$CURRENT_DIR//local/libprotobuf/:$PROTOBUF_PREFIX

# clone source repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/orc/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/$(echo $PACKAGE_VERSION | sed 's/^v//')/g" pyproject.toml
echo "--------------------------replaced version in pyproject.toml--------------------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/orc/orc.patch
git apply orc.patch

mkdir prefix
export PREFIX=$(pwd)/prefix
mkdir build && cd build

export HOST=$(uname)-$(uname -m)

CPPFLAGS="${CPPFLAGS} -Wl,-rpath,$VIRTUAL_ENV_PATH/**/lib"

# in cmake args below we are not building java components by keeping "-DBUILD_JAVA=False" as this package is build time dependency of arrow which need only cpp components of orc not java components. If you want to build java components, then change "-DBUILD_JAVA=False" to "-DBUILD_JAVA=True"
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
    -DPROTOBUF_EXECUTABLE=$PROTOBUF_PREFIX/bin/protoc \
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

# During wheel creation for this package we need exported cmake-args. Once script gets exit, and if we build wheel through wrapper script, then those are not applicable during wheel creation. So we are generating wheel for this package in script itself.
echo "---------------------------------------------------Building the wheel--------------------------------------------------"
python3 -m pip install --upgrade build setuptools wheel
python3 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

echo "----------------------------------------------Testing pkg-------------------------------------------------------"
cd build
# Test package
if ! (ninja test) ; then
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
