#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : grpc-cpp
# Version       : v1.80.0
# Source repo   : https://github.com/grpc/grpc
# Tested on     : UBI:10.2
# Language      : Python, C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Nayana Thorat <Nayana.Thorat1@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=grpccpp
PACKAGE_DIR=grpccpp
PACKAGE_VERSION=${1:-1.80.0}
PACKAGE_URL=https://github.com/grpc/grpc
    
yum install -y python3.14 python3.14-pip git make cmake zlib-devel libjpeg-devel gcc-toolset-15 wget openssl-devel
python3.14 -m pip install ninja setuptools

# Use GCC Toolset 15
export PATH=/opt/rh/gcc-toolset-15/root/usr/bin:$PATH

export CC="$(which gcc)"
export CXX="$(which g++)"

echo "CC  = ${CC}"
echo "CXX = ${CXX}"
echo "GCC = $(gcc --version | head -1)"
echo "G++ = $(g++ --version | head -1)"

SCRIPT_DIR=$(pwd)

echo "-----------c-ares installing------------------"
git clone -b cares-1_19_1 https://github.com/c-ares/c-ares
cd c-ares

export CA_PREFIX="$(pwd)/prefix"
mkdir -p "$CA_PREFIX"

mkdir -p build
cd build

AR="$(which ar)"

echo "CA_PREFIX=$CA_PREFIX"

cmake -GNinja .. \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$CA_PREFIX" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCARES_STATIC=OFF \
    -DCARES_SHARED=ON \
    -DCARES_INSTALL=ON \
    -DCMAKE_AR="$AR"

# Build.
echo "Building..."
ninja -v
ninja install

cd $SCRIPT_DIR

echo "-----------re2 installing------------------"
git clone https://github.com/google/re2.git
cd re2
git checkout 2022-04-01

mkdir -p $(pwd)/local/re2
export RE2_PREFIX=$(pwd)/local/re2
export CPU_COUNT=`nproc`

mkdir build-cmake
cd build-cmake

cmake ${CMAKE_ARGS} -GNinja \
  -DCMAKE_PREFIX_PATH=$RE2_PREFIX \
  -DCMAKE_INSTALL_PREFIX="${RE2_PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DENABLE_TESTING=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  ..

ninja -v install

echo " -------------------------Building protobuf ---------------------------------------------- "
cd $SCRIPT_DIR
git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v33.6
git submodule update --init --recursive


LIBPROTO_DIR=$(pwd)
mkdir -p $LIBPROTO_DIR/local/libprotobuf
LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf
export PROTOBUF_PREFIX=$LIBPROTO_INSTALL


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

cd $SCRIPT_DIR

echo "------- grpc-cpp installing----------------------"

git clone -b $PACKAGE_VERSION $PACKAGE_URL
cd grpc
git submodule update --init

mkdir prefix
export PREFIX=$(pwd)/prefix

AR=`which ar`
RANLIB=`which ranlib`

PROTOC_BIN=$LIBPROTO_INSTALL/bin/protoc
PROTOBUF_SRC=$LIBPROTO_DIR

export CMAKE_PREFIX_PATH="$CA_PREFIX:$RE2_PREFIX:$LIBPROTO_DIR:$LIBPROTO_INSTALL"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LIBPROTO_INSTALL/lib:$CA_PREFIX/lib:$RE2_PREFIX/lib:${LD_LIBRARY_PATH}"

export ABSL_DIR="$LIBPROTO_INSTALL/lib64/cmake/absl"
export Protobuf_DIR="$LIBPROTO_INSTALL/lib64/cmake/protobuf"

target_platform=$(uname)-$(uname -m)

export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"

mkdir -p build-cpp
cd build-cpp

cmake ${CMAKE_ARGS} ..  \
      -GNinja \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DgRPC_CARES_PROVIDER="package" \
      -DCARES_INCLUDE_DIR="$CA_PREFIX/include" \
      -DgRPC_GFLAGS_PROVIDER="package" \
      -DgRPC_PROTOBUF_PROVIDER="package" \
      -DProtobuf_ROOT=$LIBPROTO_INSTALL \
      -DProtobuf_DIR="$LIBPROTO_INSTALL/lib64/cmake/protobuf" \
      -DgRPC_SSL_PROVIDER="package" \
      -DgRPC_ZLIB_PROVIDER="package" \
      -DgRPC_ABSL_PROVIDER="package" \
      -Dabsl_DIR="$LIBPROTO_INSTALL/lib64/cmake/absl" \
      -DgRPC_RE2_PROVIDER="package" \
      -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
      -DCMAKE_AR=${AR} \
      -DCMAKE_RANLIB=${RANLIB} \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DProtobuf_PROTOC_EXECUTABLE=$PROTOC_BIN

ninja install -v

cd "${SCRIPT_DIR}"

mkdir -p local/grpccpp

cp -r grpc/prefix/* local/grpccpp/

echo "------------------ Downloading pyproject.toml ------------------"

wget -O pyproject.toml \
    https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/g/grpc-cpp/pyproject.toml

sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION}/g" pyproject.toml

echo "------------------ Building Python wheel ------------------"

python3.14 -m pip wheel \
    -w "${SCRIPT_DIR}" \
    -vv \
    --no-build-isolation \
    --no-deps \
    .

echo "------------------ Installing grpccpp ------------------"

if ! python3.14 -m pip install . ; then
    echo "------------------${PACKAGE_NAME}:Install_fails-------------------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_Fails"
    exit 1
fi
