#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyarrow
# Version       : apache-arrow-24.0.0
# Source repo   : https://github.com/apache/arrow
# Tested on     : UBI:10.1
# Language      : Python, C
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

set -e

PACKAGE_NAME=pyarrow
PACKAGE_DIR=arrow/python
PACKAGE_VERSION=${1:-apache-arrow-24.0.0}
PACKAGE_URL=https://github.com/apache/arrow
version=$(echo "$PACKAGE_VERSION" | sed 's/^apache-arrow-//')
CURRENT_DIR="${PWD}"

echo "Install dependencies and tools."

yum install -y \
    python3.12 \
    python3.12-devel \
    python3.12-pip \
    wget \
    git \
    make \
    cmake \
    xz-devel \
    openssl-devel \
    zlib-devel \
    libjpeg-devel \
    gcc \
    gcc-c++ \
    libevent \
    libtool \
    pkg-config \
    bzip2-devel \
    lz4-devel \
    libffi-devel \
    perl-Unicode-Normalize \
    patch \
    tzdata \
    binutils \
    ninja-build \
    brotli \
    brotli-devel

SCRIPT_DIR=$(pwd)

python3.12 -m pip install \
    numpy==2.2.6 \
    ninja \
    setuptools \
    setuptools_scm \
    scikit-build-core \
    wheel \
    Cython

export CC="$(which gcc)"
export CXX="$(which g++)"

# Do not globally set CMAKE_CXX_STANDARD here.
# Different dependencies use different C++ standards.

echo "---------------------------------------c-ares installing---------------------------------------"

git clone -b cares-1_19_1 https://github.com/c-ares/c-ares
cd c-ares

export CA_PREFIX="$(pwd)/prefix"
mkdir -p "$CA_PREFIX"

mkdir -p build
cd build

AR="$(which ar)"

cmake -GNinja .. \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$CA_PREFIX" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCARES_STATIC=OFF \
    -DCARES_SHARED=ON \
    -DCARES_INSTALL=ON \
    -DCMAKE_AR="$AR"

ninja -v
ninja install

cd "$SCRIPT_DIR"

echo "---------------------------------------c-ares installed----------------------------------------"

echo "---------------------------------------xsimd installing----------------------------------------"

git clone -b 14.0.0 https://github.com/xtensor-stack/xsimd/
cd xsimd

git submodule update --init

mkdir -p prefix
export XS_PREFIX="$(pwd)/prefix"

INCLUDE_PATH="${XS_PREFIX}/include"
LIBRARY_PATH="${XS_PREFIX}/lib"

export CXXFLAGS_XSIMD="-fPIC"

mkdir build-cmake
cd build-cmake

cmake \
    -GNinja \
    -DCMAKE_PREFIX_PATH="$XS_PREFIX" \
    -DCMAKE_INSTALL_PREFIX="$XS_PREFIX" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    ..

ninja
ninja install

cd "$SCRIPT_DIR"

echo "---------------------------------------xsimd installed----------------------------------------"

echo "---------------------------------------utf8proc installing------------------------------------"

git clone -b v2.6.1 https://github.com/JuliaStrings/utf8proc
cd utf8proc

git submodule update --init

mkdir -p prefix
export UTF_PREFIX="$(pwd)/prefix"

mkdir -p build
cd build

cmake -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${UTF_PREFIX}" \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=ON \
    ..

cmake --build . -j"$(nproc)"
cmake --build . --target install

cd "$SCRIPT_DIR"

echo "---------------------------------------utf8proc installed-------------------------------------"

echo "---------------------------------------re2 installing-----------------------------------------"

git clone https://github.com/google/re2.git
cd re2

git checkout 2022-04-01
git submodule update --init

mkdir -p local/re2
export RE2_PREFIX="$(pwd)/local/re2"

export CPU_COUNT="$(nproc)"

mkdir build-cmake
cd build-cmake

cmake \
    -GNinja \
    -DCMAKE_PREFIX_PATH="$RE2_PREFIX" \
    -DCMAKE_INSTALL_PREFIX="$RE2_PREFIX" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DENABLE_TESTING=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    ..

ninja -v install

cd "$SCRIPT_DIR"

echo "---------------------------------------re2 installed------------------------------------------"

echo "---------------------------------------snappy installing--------------------------------------"

git clone -b 1.2.2 https://github.com/google/snappy
cd snappy

git submodule update --init

mkdir -p local/snappy
export S_PREFIX="$(pwd)/local/snappy"

mkdir -p build
cd build

cmake \
    -DCMAKE_INSTALL_PREFIX="$S_PREFIX" \
    -DBUILD_SHARED_LIBS=ON \
    -DSNAPPY_BUILD_STATIC=OFF \
    -DCMAKE_INSTALL_LIBDIR=lib \
    ..

make -j"$(nproc)"
make install

cd "$SCRIPT_DIR"

echo "---------------------------------------snappy installed--------------------------------------"

echo "---------------------------------------flex installing---------------------------------------"

wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
tar -xvf flex-2.6.4.tar.gz

cd flex-2.6.4

./configure --prefix=/usr

make -j"$(nproc)"
make install

cd "$SCRIPT_DIR"

echo "---------------------------------------flex installed----------------------------------------"

echo "---------------------------------------texinfo installing------------------------------------"

wget https://ftp.gnu.org/gnu/texinfo/texinfo-7.1.tar.gz
tar -xzf texinfo-7.1.tar.gz

cd texinfo-7.1

./configure --prefix=/usr
make -j"$(nproc)"
make install

cd "$SCRIPT_DIR"

echo "---------------------------------------texinfo installed-------------------------------------"

echo "---------------------------------------bison installing--------------------------------------"

wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
tar -xvf bison-3.8.2.tar.gz

cd bison-3.8.2

./configure --prefix=/usr
make -j"$(nproc)"
make install

cd "$SCRIPT_DIR"

echo "---------------------------------------bison installed---------------------------------------"

echo "---------------------------------------gflags installing--------------------------------------"

git clone https://github.com/gflags/gflags.git
cd gflags
mkdir build && cd build
cmake ..
make -j$(nproc)
make install

cd $SCRIPT_DIR
echo "---------------------------------------gflags installed---------------------------------------"

echo "---------------------------------------boost installing--------------------------------------"

git clone -b boost-1.81.0 https://github.com/boostorg/boost
cd boost

git submodule update --init

mkdir -p boostcpp
export BOOST_PREFIX="$(pwd)/boostcpp"

INCLUDE_PATH="${BOOST_PREFIX}/include"
LIBRARY_PATH="${BOOST_PREFIX}/lib"

export BOOST_CXXFLAGS="-fPIC"
TOOLSET=gcc

cat > tools/build/example/site-config.jam <<EOF
using ${TOOLSET} : : ${CXX} ;
EOF

LINKFLAGS="-L${LIBRARY_PATH}"

BOOST_CXXFLAGS="$(echo "${BOOST_CXXFLAGS}" | \
    sed 's/ -march=[^ ]*//g' | \
    sed 's/ -mcpu=[^ ]*//g' | \
    sed 's/ -mtune=[^ ]*//g')"

BOOST_CFLAGS="$(echo "${CFLAGS:-}" | \
    sed 's/ -march=[^ ]*//g' | \
    sed 's/ -mcpu=[^ ]*//g' | \
    sed 's/ -mtune=[^ ]*//g')"

CXX=${CXX_FOR_BUILD:-${CXX}} \
CC=${CC_FOR_BUILD:-${CC}} \
./bootstrap.sh \
    --prefix="${BOOST_PREFIX}" \
    --without-libraries=python \
    --with-toolset="${TOOLSET}" \
    --with-icu="${BOOST_PREFIX}" \
    || (cat bootstrap.log; exit 1)

ADDRESS_MODEL=64
ARCHITECTURE=power
ABI="sysv"
BINARY_FORMAT="elf"

export CPU_COUNT="$(nproc)"

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
    toolset="${TOOLSET}" \
    include="${INCLUDE_PATH}" \
    cxxflags="${BOOST_CXXFLAGS} -Wno-deprecated-declarations" \
    linkflags="${LINKFLAGS}" \
    --layout=system \
    -j"${CPU_COUNT}" \
    install

rm -f "${BOOST_PREFIX}/include/boost/python.hpp"
rm -rf "${BOOST_PREFIX}/include/boost/python"

cd "$SCRIPT_DIR"

echo "---------------------------------------boost installed---------------------------------------"

echo "---------------------------------------libprotobuf installing--------------------------------"

export C_COMPILER="$(which gcc)"
export CXX_COMPILER="$(which g++)"

git clone https://github.com/protocolbuffers/protobuf
cd protobuf

git checkout v6.31.1
git submodule update --init --recursive

git apply "$SCRIPT_DIR/0001-Fixed-CVE-2026-0994-for-protobuf-6.31.1.patch"

LIBPROTO_DIR="$(pwd)"
mkdir -p "$LIBPROTO_DIR/local/libprotobuf"

LIBPROTO_INSTALL="$LIBPROTO_DIR/local/libprotobuf"
export PROTOBUF_PREFIX="$LIBPROTO_INSTALL"

mkdir build
cd build

cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON \
    -DCMAKE_C_COMPILER="$C_COMPILER" \
    -DCMAKE_CXX_COMPILER="$CXX_COMPILER" \
    -DCMAKE_INSTALL_PREFIX="$LIBPROTO_INSTALL" \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER=module \
    -Dprotobuf_JSONCPP_PROVIDER=package \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..

cmake --build . --verbose
cmake --install .

cd "$SCRIPT_DIR"

echo "---------------------------------------libprotobuf installed--------------------------------"

echo "---------------------------------------ZSTD installing---------------------------------------"

git clone https://github.com/facebook/zstd.git
cd zstd

make -j"$(nproc)"
make install

export ZSTD_HOME=/usr/local
export CMAKE_PREFIX_PATH="$ZSTD_HOME:$CMAKE_PREFIX_PATH"
export LD_LIBRARY_PATH="$ZSTD_HOME/lib:$LD_LIBRARY_PATH"

cd "$SCRIPT_DIR"

echo "----------------------------------------ZSTD installed--------------------------------------"

echo "-----------------------------------------orc installing---------------------------------------"

git clone https://github.com/apache/orc
cd orc

git checkout v2.0.3

git apply "$CURRENT_DIR/cmake_orc.patch"
git apply "$CURRENT_DIR/orc.patch"

mkdir -p prefix
export ORC_PREFIX="$(pwd)/prefix"

mkdir build
cd build

export ORC_CFLAGS="-fPIC"
export ORC_CXXFLAGS="-fPIC"

export CPPFLAGS="${CPPFLAGS:-} -Wl,-rpath,${VIRTUAL_ENV_PATH}/lib"

cmake \
    -GNinja \
    -DCMAKE_PREFIX_PATH="$ORC_PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_JAVA=OFF \
    -DLZ4_HOME=/usr \
    -DZLIB_HOME=/usr \
    -DZSTD_HOME=/usr \
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
    -DProtobuf_ROOT="$PROTOBUF_PREFIX" \
    -DPROTOBUF_HOME="$PROTOBUF_PREFIX" \
    -DPROTOBUF_PROTOC_EXECUTABLE="$PROTOBUF_PREFIX/bin/protoc" \
    -DSNAPPY_HOME="$S_PREFIX" \
    -DBUILD_LIBHDFSPP=NO \
    -DBUILD_CPP_TESTS=ON \
    -DCMAKE_INSTALL_PREFIX="$ORC_PREFIX" \
    -DCMAKE_C_COMPILER="$(type -p "${CC}")" \
    -DCMAKE_CXX_COMPILER="$(type -p "${CXX}")" \
    -DCMAKE_C_FLAGS="-fPIC" \
    -DCMAKE_CXX_FLAGS="-fPIC -Wno-unused-parameter" \
    ${_CMAKE_EXTRA_CONFIG:-} \
    ..

ninja
ninja install

cd "$SCRIPT_DIR"

echo "-----------------------------------------orc installed------------------------------------------"

echo "-----------------------------------------thrift installing---------------------------------------"

git clone https://github.com/apache/thrift
cd thrift

git checkout 0.21.0

mkdir -p prefix
export THRIFT_PREFIX="$(pwd)/prefix"

export BOOST_ROOT="${BOOST_PREFIX}"
export ZLIB_ROOT=/usr
export LIBEVENT_ROOT=/usr
export OPENSSL_ROOT=/usr
export OPENSSL_ROOT_DIR=/usr

./bootstrap.sh

./configure \
    --prefix="$THRIFT_PREFIX" \
    --with-python=no \
    --with-py3=no \
    --with-ruby=no \
    --with-java=no \
    --with-kotlin=no \
    --with-erlang=no \
    --with-nodejs=no \
    --with-c_glib=no \
    --with-haxe=no \
    --with-rs=no \
    --with-cpp=yes \
    --with-PACKAGE=yes \
    --with-zlib="$ZLIB_ROOT" \
    --with-libevent="$LIBEVENT_ROOT" \
    --with-boost="$BOOST_ROOT" \
    --with-openssl="$OPENSSL_ROOT" \
    --enable-tests=no \
    --enable-tutorial=no

make -j"$(nproc)"
make install

cd "$SCRIPT_DIR"

echo "-------------------------------------------thrift installed--------------------------------"

echo "--------------------------------------------grpc-cpp installing-----------------------------"

git clone -b v1.71.0 https://github.com/grpc/grpc
cd grpc

git submodule update --init

mkdir -p prefix
export GRPC_PREFIX="$(pwd)/prefix"

AR="$(which ar)"
RANLIB="$(which ranlib)"

PROTOC_BIN="$LIBPROTO_INSTALL/bin/protoc"
PROTOBUF_SRC="$LIBPROTO_DIR"

export CMAKE_PREFIX_PATH="${CA_PREFIX}:${RE2_PREFIX}:${LIBPROTO_INSTALL}:${CMAKE_PREFIX_PATH}"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LIBPROTO_INSTALL/lib:$CA_PREFIX/lib:$RE2_PREFIX/lib:${LD_LIBRARY_PATH}"

export ABSL_DIR="$LIBPROTO_INSTALL/lib64/cmake/absl"
export Protobuf_DIR="$LIBPROTO_INSTALL/lib64/cmake/protobuf"

# IMPORTANT:
# Do NOT put C++17 into the global CMAKE_ARGS.
# gRPC gets its own C++17 setting.

export GRPC_CMAKE_ARGS="-DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_STANDARD_REQUIRED=ON"

mkdir -p build-cpp
cd build-cpp

cmake \
    -GNinja \
    ${GRPC_CMAKE_ARGS} \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$GRPC_PREFIX" \
    -DgRPC_CARES_PROVIDER=package \
    -DCARES_INCLUDE_DIR="$CA_PREFIX/include" \
    -DgRPC_GFLAGS_PROVIDER=package \
    -DgRPC_PROTOBUF_PROVIDER=package \
    -DProtobuf_ROOT="$LIBPROTO_INSTALL" \
    -DProtobuf_DIR="$LIBPROTO_INSTALL/lib64/cmake/protobuf" \
    -DgRPC_SSL_PROVIDER=package \
    -DgRPC_ZLIB_PROVIDER=package \
    -DgRPC_ABSL_PROVIDER=package \
    -Dabsl_DIR="$LIBPROTO_INSTALL/lib64/cmake/absl" \
    -DgRPC_RE2_PROVIDER=package \
    -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH" \
    -DCMAKE_AR="$AR" \
    -DCMAKE_RANLIB="$RANLIB" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DProtobuf_PROTOC_EXECUTABLE="$PROTOC_BIN" \
    ..

ninja install -v

cd "$SCRIPT_DIR"

echo "--------------------------------------------grpc-cpp installed-----------------------------"

echo "--------------------------------------------rapidjson installing----------------------------"

git clone -b v1.1.0 --depth 1 https://github.com/Tencent/rapidjson.git
cd rapidjson

export RJ_PREFIX="$(pwd)/prefix"

mkdir -p "$RJ_PREFIX/include"
cp -a include/rapidjson "$RJ_PREFIX/include/"

sed -i \
    's/GenericStringRef& operator=(const GenericStringRef& rhs) { s = rhs.s; length = rhs.length; }/GenericStringRef\& operator=(const GenericStringRef\& rhs) { s = rhs.s; return *this; }/' \
    "$RJ_PREFIX/include/rapidjson/document.h"

cd "$SCRIPT_DIR"

echo "--------------------------------------------rapidjson installed-------------------------------"

echo "--------------------------------------------pyarrow installing--------------------------------"

git clone "$PACKAGE_URL"
cd arrow

git fetch --tags
git checkout --force "$PACKAGE_VERSION"
git submodule update --init --recursive

export SETUPTOOLS_SCM_PRETEND_VERSION="$version"

mkdir -p pyarrow_prefix
export PYARROW_PREFIX="$(pwd)/pyarrow_prefix"
export ARROW_HOME="$PYARROW_PREFIX"

export target_platform="$(uname)-$(uname -m)"

export AR="$(which ar)"
export RANLIB="$(which ranlib)"

export CC="$(which gcc)"
export CXX="$(which g++)"

export CMAKE_PREFIX_PATH="${CA_PREFIX}:${XS_PREFIX}:${UTF_PREFIX}:${RE2_PREFIX}:${S_PREFIX}:${BOOST_PREFIX}:${PROTOBUF_PREFIX}:${ORC_PREFIX}:${THRIFT_PREFIX}:${GRPC_PREFIX}:${ZSTD_HOME}:/usr:${CMAKE_PREFIX_PATH}"

export LD_LIBRARY_PATH="${GRPC_PREFIX}/lib:${PROTOBUF_PREFIX}/lib64:${ORC_PREFIX}/lib:${THRIFT_PREFIX}/lib:${BOOST_PREFIX}/lib:${RE2_PREFIX}/lib:${CA_PREFIX}/lib:${XS_PREFIX}/lib:${UTF_PREFIX}/lib:${S_PREFIX}/lib:${ZSTD_HOME}/lib:/usr/lib64:/usr/lib:${LD_LIBRARY_PATH}"

export PKG_CONFIG_PATH="${GRPC_PREFIX}/lib/pkgconfig:${PROTOBUF_PREFIX}/lib64/pkgconfig:${PROTOBUF_PREFIX}/lib/pkgconfig:${ORC_PREFIX}/lib/pkgconfig:${THRIFT_PREFIX}/lib/pkgconfig:${BOOST_PREFIX}/lib/pkgconfig:${RE2_PREFIX}/lib/pkgconfig:${CA_PREFIX}/lib/pkgconfig:${S_PREFIX}/lib/pkgconfig:${ZSTD_HOME}/lib/pkgconfig:${PKG_CONFIG_PATH}"

export Protobuf_DIR="${PROTOBUF_PREFIX}/lib64/cmake/protobuf"
export ABSL_DIR="${PROTOBUF_PREFIX}/lib64/cmake/absl"
export gRPC_DIR="${GRPC_PREFIX}/lib/cmake/grpc"
export BOOST_ROOT="${BOOST_PREFIX}"

# -------------------------------------------------------------------------
# IMPORTANT:
# Arrow 24.0.0 requires C++20.
#
# Do not inherit C++17 from gRPC.
# -------------------------------------------------------------------------

unset CFLAGS
export CXXFLAGS="-std=c++20 -fPIC -I${BOOST_PREFIX}/include -I${THRIFT_PREFIX}/include"
export CFLAGS="-fPIC"

# Clear any CMAKE_ARGS inherited from earlier dependency builds.
unset CMAKE_ARGS

# Arrow uses C++20.
export CMAKE_ARGS="-DCMAKE_CXX_STANDARD=20 -DCMAKE_CXX_STANDARD_REQUIRED=ON -DCMAKE_CXX_EXTENSIONS=OFF"

mkdir -p cpp/build
cd cpp/build

EXTRA_CMAKE_ARGS=""

SYSTEM_INCLUDES=$(
    echo |
    ${CXX} -E -Wp,-v -xc++ - 2>&1 |
    grep '^ ' |
    awk '{print "-isystem;" substr($1, 1)}' |
    tr '\n' ';'
)

EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DARROW_GANDIVA_PC_CXX_FLAGS=${SYSTEM_INCLUDES}"

EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DARROW_CUDA=OFF"

# Disable Gandiva

EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DARROW_GANDIVA=OFF"

# SIMD

EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_ALTIVEC=ON"

sed -ie \
    's;"--with-jemalloc-prefix=je_arrow_";"--with-jemalloc-prefix=je_arrow_" "--with-lg-page=16";g' \
    ../cmake_modules/ThirdpartyToolchain.cmake

echo "============================================================"
echo "Arrow C++ configuration"
echo "CMAKE_ARGS=${CMAKE_ARGS}"
echo "CXXFLAGS=${CXXFLAGS}"
echo "============================================================"

cmake \
    -GNinja \
    ${CMAKE_ARGS} \
    ${EXTRA_CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="${CC}" \
    -DCMAKE_CXX_COMPILER="${CXX}" \
    -DCMAKE_CXX_STANDARD=20 \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON \
    -DCMAKE_CXX_EXTENSIONS=OFF \
    -DCMAKE_AR="${AR}" \
    -DCMAKE_RANLIB="${RANLIB}" \
    -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
    -DCMAKE_INSTALL_PREFIX="${ARROW_HOME}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=ON \
    -DARROW_DEPENDENCY_SOURCE=SYSTEM \
    -DARROW_BUILD_BENCHMARKS=OFF \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_BUILD_UTILITIES=OFF \
    -DARROW_BUILD_STATIC=OFF \
    -DARROW_DATASET=ON \
    -DARROW_FLIGHT=ON \
    -DARROW_HDFS=ON \
    -DARROW_ORC=ON \
    -DARROW_PARQUET=ON \
    -DARROW_PYTHON=ON \
    -DARROW_S3=OFF \
    -DARROW_JEMALLOC=ON \
    -DARROW_MIMALLOC=ON \
    -DARROW_WITH_BROTLI=ON \
    -DARROW_WITH_BZ2=ON \
    -DARROW_WITH_LZ4=ON \
    -DARROW_WITH_SNAPPY=ON \
    -DARROW_WITH_ZLIB=ON \
    -DARROW_WITH_ZSTD=ON \
    -DARROW_WITH_THRIFT=ON \
    -DARROW_BOOST_USE_SHARED=ON \
    -DProtobuf_ROOT="${PROTOBUF_PREFIX}" \
    -DProtobuf_DIR="${Protobuf_DIR}" \
    -DPROTOBUF_PROTOC_EXECUTABLE="${PROTOBUF_PREFIX}/bin/protoc" \
    -DgRPC_DIR="${gRPC_DIR}" \
    -DgRPC_ABSL_PROVIDER=package \
    -DgRPC_PROTOBUF_PROVIDER=package \
    -DgRPC_ZLIB_PROVIDER=package \
    -DgRPC_SSL_PROVIDER=package \
    -DgRPC_RE2_PROVIDER=package \
    -DgRPC_CARES_PROVIDER=package \
    -Dabsl_DIR="${ABSL_DIR}" \
    -DCARES_INCLUDE_DIR="${CA_PREFIX}/include" \
    -DCARES_LIBRARY="${CA_PREFIX}/lib/libcares.so" \
    -DRE2_INCLUDE_DIR="${RE2_PREFIX}/include" \
    -DRE2_LIBRARY="${RE2_PREFIX}/lib/libre2.so" \
    -DSnappy_INCLUDE_DIR="${S_PREFIX}/include" \
    -DSnappy_LIBRARY="${S_PREFIX}/lib/libsnappy.so" \
    -DORC_INCLUDE_DIR="${ORC_PREFIX}/include" \
    -DORC_LIBRARY="${ORC_PREFIX}/lib/liborc.so" \
    -DThrift_INCLUDE_DIR="${THRIFT_PREFIX}/include" \
    -DThrift_LIBRARY="${THRIFT_PREFIX}/lib/libthrift.so" \
    -DBoost_ROOT="${BOOST_PREFIX}" \
    -DBoost_INCLUDE_DIR="${BOOST_PREFIX}/include" \
    -Dutf8proc_INCLUDE_DIR="${UTF_PREFIX}/include" \
    -Dutf8proc_LIB="${UTF_PREFIX}/lib/libutf8proc.so" \
    -DZSTD_ROOT="${ZSTD_HOME}" \
    -DZSTD_INCLUDE_DIR="${ZSTD_HOME}/include" \
    -DZSTD_LIBRARY="${ZSTD_HOME}/lib/libzstd.so" \
    -DLZ4_HOME=/usr \
    -DZLIB_HOME=/usr \
    -DPYTHON_EXECUTABLE="${PYTHON_EXECUTABLE:-$(which python3.12)}" \
    -DPython3_EXECUTABLE="${Python3_EXECUTABLE:-$(which python3.12)}" \
    -DRapidJSON_ROOT="${RJ_PREFIX}" \
    ..

ninja -v
ninja install

export PYARROW_BUNDLE_ARROW_CPP=ON
export PYARROW_BUNDLE_ARROW_CPP_HEADERS=ON

export LD_LIBRARY_PATH="${ARROW_HOME}/lib:${LD_LIBRARY_PATH}"
export CMAKE_PREFIX_PATH="${ARROW_HOME}:${CMAKE_PREFIX_PATH}"
export CMAKE_GENERATOR=Ninja

export Arrow_DIR="${ARROW_HOME}/lib/cmake/Arrow"

# Build dependencies

export PARQUET_HOME="$ARROW_HOME"
export SETUPTOOLS_SCM_PRETEND_VERSION="$version"

export PYARROW_WITH_DATASET=1
export PYARROW_WITH_FLIGHT=1
export PYARROW_WITH_GANDIVA=0
export PYARROW_WITH_HDFS=1
export PYARROW_WITH_ORC=1
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_S3=0

export PYARROW_WITH_CUDA=0

echo "--------------------------------------------pyarrow installed--------------------------------"

echo "--------------------------------------------pyarrow wheel building---------------------------"

cd "$SCRIPT_DIR/arrow/python"

# -------------------------------------------------------------------------
# Remove any previous scikit-build-core/CMake cache.
# This is important because the PyArrow wheel performs a NEW CMake
# configuration and an old cache can contain C++17.
# -------------------------------------------------------------------------

rm -rf build
rm -rf _skbuild

# Make C++20 explicit for the PyArrow wheel.
export CXXFLAGS="-std=c++20 -fPIC -I${BOOST_PREFIX}/include -I${THRIFT_PREFIX}/include"
export CFLAGS="-fPIC"

export CMAKE_ARGS="-DCMAKE_CXX_STANDARD=20 -DCMAKE_CXX_STANDARD_REQUIRED=ON -DCMAKE_CXX_EXTENSIONS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DArrow_DIR=${Arrow_DIR}"

echo "============================================================"
echo "PyArrow wheel configuration"
echo "CMAKE_ARGS=${CMAKE_ARGS}"
echo "CXXFLAGS=${CXXFLAGS}"
echo "Arrow_DIR=${Arrow_DIR}"
echo "============================================================"

python3.12 -m pip wheel \
    -w "$SCRIPT_DIR" \
    -vv \
    --no-build-isolation \
    --no-deps \
    -C cmake.build-type=Release \
    -C build.verbose=true \
    .

cd "$SCRIPT_DIR"

echo "--------------------------------------------pyarrow wheel build completed---------------------------"

echo "--------------------------------------------Testing pyarrow-----------------------------------------"

WHEEL=$(find "${SCRIPT_DIR}" -maxdepth 1 -name "${PACKAGE_NAME}-*.whl" | head -1)
python3.12 -m pip install "${WHEEL}" --no-deps
SITE_PACKAGES=$(python3.12 -m pip show pyarrow | awk -F': ' '/^Location:/ {print $2}')

export LD_LIBRARY_PATH="${GRPC_PREFIX}/lib:${PROTOBUF_PREFIX}/lib64:${ORC_PREFIX}/lib:${THRIFT_PREFIX}/lib:${BOOST_PREFIX}/lib:${RE2_PREFIX}/lib:${CA_PREFIX}/lib:${XS_PREFIX}/lib:${UTF_PREFIX}/lib:${S_PREFIX}/lib:${ZSTD_HOME}/lib:/usr/lib64:/usr/lib:$SITE_PACKAGES/pyarrow:${LD_LIBRARY_PATH}"

python3.12 -m pip install -r $SCRIPT_DIR/arrow/python/requirements-test.txt "pytest<9"

PYARROW_LOCATION=$(python3.12 -c "import os; import pyarrow; print(os.path.dirname(pyarrow.__file__))")
export PARQUET_TEST_DATA="$SCRIPT_DIR/arrow/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA=$SCRIPT_DIR/arrow/testing/data

if ! python3.12 -m pytest -k "not test_foreign_buffer and not test_get_include and not pandas" $PYARROW_LOCATION -vv ; then
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

echo "--------------------------------------------Testing pyarrow completed --------------------------------"

