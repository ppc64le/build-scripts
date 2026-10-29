#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : airflow
# Version       : 3.0.2
# Source repo   : https://github.com/apache/airflow
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: airflow_ubi_9.3.sh
#   - Has patch commands
#   - Has workaround commands
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="airflow"
PACKAGE_VERSION="${1:-3.0.2}"
PACKAGE_URL="https://github.com/apache/airflow"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="brotli-devel bzip2-devel cmake gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ git krb5-devel krb5-workstation libevent libffi-devel libjpeg-devel libpq-devel librdkafka-devel libtool libxml2 libxml2-devel libxslt libxslt-devel lz4 lz4-devel make mariadb-connector-c-devel mysql openldap-devel openssl openssl-devel pkg-config pkgconf-pkg-config python3 python3-devel python3-pip sqlite-devel tar unixODBC-devel wget xz-devel zip zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export CFLAGS="-mcpu=power9 -mtune=power10 ${CFLAGS}"
export CXXFLAGS="-mcpu=power9 -mtune=power10 ${CXXFLAGS}"
export C_ARES_PREFIX=$(pwd)/c_ares_prefix
export SNAPPY_PREFIX=$(pwd)/local/snappy
export ZSTD_HOME=/usr/local
export CMAKE_PREFIX_PATH=$ZSTD_HOME
export LD_LIBRARY_PATH=$ZSTD_HOME/lib64:$LD_LIBRARY_PATH
export CPU_COUNT=`nproc`
export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)
export ORC_PREFIX=$(pwd)/orc_prefix
export PROTOBUF_PREFIX=$LIBPROTO_INSTALL
export CMAKE_PREFIX_PATH=$LIBPROTO_INSTALL
export LD_LIBRARY_PATH=$LIBPROTO_INSTALL/lib64
export CC=$(which gcc)
export CXX=$(which g++)
export GCC=$CC
export GXX=$CXX
export HOST=$(uname)-$(uname -m)
export HOST=$(uname)-$(uname -m)
export BOOST_PREFIX=$(pwd)/Boost_prefix
export CC=$(which gcc)
export CXX=$(which g++)
export THRIFT_PREFIX=$Source_DIR/thrit-prefix
export BOOST_ROOT=${BOOST_PREFIX}
export ZLIB_ROOT=/usr
export LIBEVENT_ROOT=/usr
export OPENSSL_ROOT=/usr
export OPENSSL_ROOT_DIR=/usr
export GRPC_PREFIX=$(pwd)/grpc-prefix
export CMAKE_PREFIX_PATH="$C_ARES_PREFIX;$RE2_PREFIX;$LIBPROTO_INSTALL"
export LD_LIBRARY_PATH=$LIBPROTO_INSTALL/lib64:${LD_LIBRARY_PATH}
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
export USE_OPENMP=1
export PREFIX=${PREFIX}
export PLATFORM=$(uname -m)
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib"
export PKG_CONFIG_PATH="$OpenBLASInstallPATH/lib/pkgconfig:${PKG_CONFIG_PATH}"
export PYARROW_PREFIX=$(pwd)/pyarrow_prefix
export ARROW_HOME=$PYARROW_PREFIX
export CXX=$(which g++)
export CMAKE_PREFIX_PATH=$C_ARES_PREFIX:$LIBPROTO_INSTALL:$RE2_PREFIX:$GRPC_PREFIX:$ORC_PREFIX:$BOOST_PREFIX:${UTF8PROC_PREFIX}:$THRIFT_PREFIX:$SNAPPY_PREFIX:/usr
export LD_LIBRARY_PATH=$GRPC_PREFIX/lib:$LIBPROTO_INSTALL/lib64
export BOOST_ROOT="${BOOST_PREFIX}"
export CXXFLAGS="-I$${BOOST_PREFIX}/include -I${THRIFT_PREFIX}/include"
export AR=$(which ar)
export RANLIB=$(which ranlib)
export PYARROW_BUNDLE_ARROW_CPP=1
export LD_LIBRARY_PATH=${ARROW_HOME}/lib:${LD_LIBRARY_PATH}
export CMAKE_PREFIX_PATH=$ARROW_HOME
export PARQUET_HOME=$ARROW_HOME
export SETUPTOOLS_SCM_PRETEND_VERSION=$version
export PYARROW_BUILD_TYPE=release
export PYARROW_BUNDLE_ARROW_CPP_HEADERS=1
export PYARROW_WITH_DATASET=1
export PYARROW_WITH_FLIGHT=1
export PYARROW_WITH_GANDIVA=0
export PYARROW_WITH_HDFS=1
export PYARROW_WITH_ORC=1
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_PLASMA=1
export PYARROW_CMAKE_GENERATOR=Ninja

# =============================================================================
# OPTIONAL: Callback functions for custom logic
# =============================================================================

# Apply patches after cloning (extracted from original script)
post_clone() {
    # TODO: Review and update patch commands from original script
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/orc/orc.patch
git apply orc.patch
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/orc/orc.patch
    git apply orc.patch
    git apply orc.patch
}

# Apply workarounds after cloning (extracted from original script)
# TODO: Merge with post_clone if both exist
_apply_workarounds() {
    sed -i "/OpenBLAS_INCLUDE_DIRS/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
    sed -i "/OpenBLAS_LIBRARIES/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
    sed -i "s|libdir=local/openblas/lib|libdir=${OpenBLASInstallPATH}/lib|" ${OpenBLASPCFile}
    sed -i "s|includedir=local/openblas/include|includedir=${OpenBLASInstallPATH}/include|" ${OpenBLASPCFile}
    sed -ie 's;"--with-jemalloc-prefix\=je_arrow_";"--with-jemalloc-prefix\=je_arrow_" "--with-lg-page\=16";g' ../cmake_modules/ThirdpartyToolchain.cmake
}

# Custom test command (extracted from original script)
custom_test_command() {
    # TODO: Review and update test commands
    python3 -m pip install "coverage>=4.0" "cython>=0.29.8,<3.0.0" "wheel>=0.29"
}

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# PACKAGE_DIR=airflow
# CURRENT_DIR=${PWD}
# export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
# export PATH=$GCC_TOOLSET_PATH/bin:$PATH
# export CFLAGS="-mcpu=power9 -mtune=power10 ${CFLAGS}"
# export CXXFLAGS="-mcpu=power9 -mtune=power10 ${CXXFLAGS}"
# curl https://sh.rustup.rs -sSf | sh -s -- -y
# source ~/.cargo/env
# pip install ninja setuptools mysqlclient
# wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
# tar -xvf flex-2.6.4.tar.gz
# cd flex-2.6.4
# echo "Configuring flex installation..."
# ./configure --prefix=/usr/local
# echo "Compiling the source code for flex..."
# make -j$(nproc)
# echo "Installing flex..."
# cd $CURRENT_DIR
# wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
# tar -xvf bison-3.8.2.tar.gz
# cd bison-3.8.2
# echo "Configuring bison installation..."
# ./configure --prefix=/usr/local
# echo "Compiling the source code bison..."
# make -j$(nproc)
# echo "Installing bison..."
# cd $CURRENT_DIR
# git clone https://github.com/gflags/gflags.git
# cd gflags
# mkdir build && cd build
# echo "Running cmake to configure the build..."
# cmake ..
# echo "Compiling the source code gflags..."
# make -j$(nproc)
# echo "Installing gflags..."
# cd $CURRENT_DIR
# git clone https://github.com/c-ares/c-ares.git
# cd c-ares
# git checkout cares-1_19_1
# target_platform=$(uname)-$(uname -m)
# AR=$(which ar)
# PKG_NAME=c-ares
# mkdir -p c_ares_prefix
# export C_ARES_PREFIX=$(pwd)/c_ares_prefix
# echo "Building ${PKG_NAME}."
# mkdir build && cd build
# if [[ "$PKG_NAME" == *static ]]; then
#   CARES_STATIC=ON
#   CARES_SHARED=OFF
#   CARES_STATIC=OFF
#   CARES_SHARED=ON
# if [[ "${target_platform}" == Linux-* ]]; then
#   CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_AR=${AR}"
# echo "Generating the build files..."
# cmake ${CMAKE_ARGS} .. \
#       -DCMAKE_BUILD_TYPE=Release \
#       -DCMAKE_INSTALL_PREFIX="$C_ARES_PREFIX" \
#       -DCARES_STATIC=${CARES_STATIC} \
#       -DCARES_SHARED=${CARES_SHARED} \
#       -DCARES_INSTALL=ON \
#       -DCMAKE_INSTALL_LIBDIR=lib \
#       -GNinja
# echo "Building c-areas..."
# ninja || exit 1
# echo "Installing c-areas..."
# ninja install || exit 1
# cd $CURRENT_DIR
# git clone https://github.com/Tencent/rapidjson.git
# cd rapidjson
# mkdir build && cd build
# echo "Running cmake to configure the build..."
# cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
# echo "Compiling the source code for rapidjson..."
# make -j$(nproc)
# echo "Installing rapidjson"
# cd $CURRENT_DIR
# git clone https://github.com/xtensor-stack/xsimd.git
# cd xsimd
# mkdir build && cd build
# echo "Running cmake to configure the build for xsimd.."
# cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
# echo "Compiling the source code for xsimd..."
# make -j$(nproc)
# echo "Installing xsimd..."
# cd $CURRENT_DIR
# git clone https://github.com/google/snappy.git
# cd snappy
# git submodule update --init --recursive
# mkdir -p local/snappy
# export SNAPPY_PREFIX=$(pwd)/local/snappy
# mkdir build
# cd build
# echo "Running cmake to configure the build for snappy..."
# cmake -DCMAKE_INSTALL_PREFIX=$SNAPPY_PREFIX \
#       -DBUILD_SHARED_LIBS=ON \
#       -DCMAKE_INSTALL_LIBDIR=lib \
#       ..
# echo "Compiling the source code for snappy..."
# make -j$(nproc)
# echo "Installing snappy..."
# cd ..
# cd $CURRENT_DIR
# git clone https://github.com/facebook/zstd.git
# cd zstd
# echo "Compiling the source code for libzstd..."
# echo "Installing libzstd..."
# export ZSTD_HOME=/usr/local
# export CMAKE_PREFIX_PATH=$ZSTD_HOME
# export LD_LIBRARY_PATH=$ZSTD_HOME/lib64:$LD_LIBRARY_PATH
# cd $CURRENT_DIR
# git clone http://github.com/google/re2
# cd re2
# git checkout 2022-04-01
# git submodule update --init
# mkdir re2-prefix
# export RE2_PREFIX=$(pwd)/re2-prefix
# export CPU_COUNT=`nproc`
# mkdir build-cmake
# pushd build-cmake
# echo "Running cmake to configure the build for re2..."
# cmake ${CMAKE_ARGS} -GNinja \
#   -DCMAKE_PREFIX_PATH=$RE2_PREFIX \
#   -DCMAKE_INSTALL_PREFIX="${RE2_PREFIX}" \
#   -DCMAKE_INSTALL_LIBDIR=lib \
#   -DENABLE_TESTING=OFF \
#   -DCMAKE_BUILD_TYPE=Release \
#   -DBUILD_SHARED_LIBS=ON \
#   ..
# echo "Installing re2..."
#   ninja -v install
#   popd
# echo "Running make shared-install......"
# make -j "${CPU_COUNT}" prefix=${RE2_PREFIX} shared-install
# cd $CURRENT_DIR
# git clone https://github.com/JuliaStrings/utf8proc.git
# cd utf8proc
# git submodule update --init
# git checkout v2.6.1
# mkdir utf8proc_prefix
# export UTF8PROC_PREFIX=$(pwd)/utf8proc_prefix
# mkdir build
# cd build
# echo "Running cmake to configure the build for utf8proc..."
# cmake -G "Unix Makefiles" \
#   -DCMAKE_BUILD_TYPE="Release" \
#   -DCMAKE_INSTALL_PREFIX="${UTF8PROC_PREFIX}" \
#   -DCMAKE_POSITION_INDEPENDENT_CODE=1 \
#   -DBUILD_SHARED_LIBS=1 \
#   ..
# echo  "Build and install utf8proc"
# cmake --build .
# echo "Installing utf8proc ..."
# cmake --build . --target install
# cd $CURRENT_DIR
# ABSEIL_VERSION=20240116.2
# ABSEIL_URL="https://github.com/abseil/abseil-cpp"
# git clone $ABSEIL_URL -b $ABSEIL_VERSION
# export C_COMPILER=$(which gcc)
# export CXX_COMPILER=$(which g++)
# git clone https://github.com/protocolbuffers/protobuf
# cd protobuf
# git checkout v4.25.8
# LIBPROTO_DIR=$(pwd)
# mkdir -p $LIBPROTO_DIR/local/libprotobuf
# LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf
# git submodule update --init --recursive
# rm -rf ./third_party/googletest | true
# rm -rf ./third_party/abseil-cpp | true
# cp -r $CURRENT_DIR/abseil-cpp ./third_party/
# mkdir build
# cd build
# echo "Running cmake to configure the build for libprotobuf..."
# cmake -G "Ninja" \
#    ${CMAKE_ARGS} \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DCMAKE_CXX_STANDARD=17 \
#     -DCMAKE_C_COMPILER=$C_COMPILER \
#     -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
#     -DCMAKE_INSTALL_PREFIX=$LIBPROTO_INSTALL \
#     -Dprotobuf_BUILD_TESTS=OFF \
#     -Dprotobuf_BUILD_LIBUPB=OFF \
#     -Dprotobuf_BUILD_SHARED_LIBS=ON \
#     -Dprotobuf_ABSL_PROVIDER="module" \
#     -Dprotobuf_JSONCPP_PROVIDER="package" \
#     -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
#     ..
# echo  "Building libprotobuf..."
# cmake --build . --verbose
# echo  "Installing libprotobuf..."
# cmake --install .
# cd $CURRENT_DIR
# git clone https://github.com/apache/orc
# cd orc
# git checkout v2.0.3
# wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/orc/orc.patch
# git apply orc.patch
# mkdir orc_prefix
# export ORC_PREFIX=$(pwd)/orc_prefix
# mkdir -p build
# cd build
# export PROTOBUF_PREFIX=$LIBPROTO_INSTALL
# export CMAKE_PREFIX_PATH=$LIBPROTO_INSTALL
# export LD_LIBRARY_PATH=$LIBPROTO_INSTALL/lib64
# export CC=$(which gcc)
# export CXX=$(which g++)
# export GCC=$CC
# export GXX=$CXX
# export HOST=$(uname)-$(uname -m)
# export HOST=$(uname)-$(uname -m)
# CPPFLAGS="${CPPFLAGS} -Wl,-rpath,$VIRTUAL_ENV_PATH/**/lib"
# declare -a _CMAKE_EXTRA_CONFIG
# if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 ]]; then
#     _CMAKE_EXTRA_CONFIG+=(-DHAS_PRE_1970_EXITCODE=0)
#     _CMAKE_EXTRA_CONFIG+=(-DHAS_PRE_1970_EXITCODE__TRYRUN_OUTPUT=)
#     _CMAKE_EXTRA_CONFIG+=(-DHAS_POST_2038_EXITCODE=0)
#     _CMAKE_EXTRA_CONFIG+=(-DHAS_POST_2038_EXITCODE__TRYRUN_OUTPUT=)
# if [[ ${HOST} =~ .*darwin.* ]]; then
#     _CMAKE_EXTRA_CONFIG+=(-DCMAKE_AR=${AR})
#     _CMAKE_EXTRA_CONFIG+=(-DCMAKE_RANLIB=${RANLIB})
#     _CMAKE_EXTRA_CONFIG+=(-DCMAKE_LINKER=${LD})
# if [[ ${HOST} =~ .*Linux.* ]]; then
#     CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"
#     LIBPTHREAD=$(find ${PREFIX} -name "libpthread.so")
#     _CMAKE_EXTRA_CONFIG+=(-DPTHREAD_LIBRARY=${LIBPTHREAD})
# CPPFLAGS="${CPPFLAGS} -Wl,-rpath,$VIRTUAL_ENV_PATH/**/lib"
# echo "Running cmake to configure the build for orc..."
# cmake ${CMAKE_ARGS} \
#     -DCMAKE_PREFIX_PATH=$ORC_PREFIX \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DBUILD_SHARED_LIBS=ON \
#     -DBUILD_JAVA=False \
#     -DLZ4_HOME=/usr \
#     -DZLIB_HOME=/usr \
#     -DZSTD_HOME=/usr/local \
#     -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
#     -DProtobuf_ROOT=$PROTOBUF_PREFIX \
#     -DPROTOBUF_HOME=$PROTOBUF_PREFIX \
#     -DPROTOBUF_EXECUTABLE=$PROTOBUF_PREFIX/bin/protoc \
#     -DSNAPPY_HOME=$SNAPPY_PREFIX \
#     -DBUILD_LIBHDFSPP=NO \
#     -DBUILD_CPP_TESTS=OFF \
#     -DCMAKE_INSTALL_PREFIX=$ORC_PREFIX \
#     -DCMAKE_C_COMPILER=$(type -p ${CC})     \
#     -DCMAKE_CXX_COMPILER=$(type -p ${CXX})  \
#     -DCMAKE_C_FLAGS="$CFLAGS"  \
#     -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-unused-parameter" \
#     "${_CMAKE_EXTRA_CONFIG[@]}" \
#     -GNinja ..
# ninja
# echo  "Installing orc..."
# ninja install
# cd $CURRENT_DIR
# git clone https://github.com/boostorg/boost
# cd boost
# git checkout boost-1.81.0
# git submodule update --init
# mkdir Boost_prefix
# export BOOST_PREFIX=$(pwd)/Boost_prefix
# INCLUDE_PATH="${BOOST_PREFIX}/include"
# LIBRARY_PATH="${BOOST_PREFIX}/lib"
# export CC=$(which gcc)
# export CXX=$(which g++)
# export target_platform=$(uname)-$(uname -m)
# CXXFLAGS="${CXXFLAGS} -fPIC"
# TOOLSET=gcc
# cat <<EOF > tools/build/example/site-config.jam
# using ${TOOLSET} : : ${CXX} ;
# EOF
# LINKFLAGS="${LINKFLAGS} -L${LIBRARY_PATH}"
# CXXFLAGS="$(echo ${CXXFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' |sed 's/ -mtune=[^ ]*//g')" \
# CFLAGS="$(echo ${CFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' |sed 's/ -mtune=[^ ]*//g')" \
#     CXX=${CXX_FOR_BUILD:-${CXX}} CC=${CC_FOR_BUILD:-${CC}} ./bootstrap.sh \
#     --prefix="${BOOST_PREFIX}" \
#     --without-libraries=python \
#     --with-toolset=${TOOLSET} \
#     --with-icu="${BOOST_PREFIX}" || (cat bootstrap.log; exit 1)
# 	 ADDRESS_MODEL=64
#     ARCHITECTURE=power
# 	ABI="sysv"
# 	 BINARY_FORMAT="elf"
# 	 export CPU_COUNT=$(nproc)
# echo " Building and installing Boost...."
# ./b2 -q \
#     variant=release \
#     address-model="${ADDRESS_MODEL}" \
#     architecture="${ARCHITECTURE}" \
#     binary-format="${BINARY_FORMAT}" \
#     abi="${ABI}" \
#     debug-symbols=off \
#     threading=multi \
#     runtime-link=shared \
#     link=shared \
#     toolset=${TOOLSET} \
#     include="${INCLUDE_PATH}" \
#     cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
#     linkflags="${LINKFLAGS}" \
#     --layout=system \
#     -j"${CPU_COUNT}" \
#     install
# rm -rf "${BOOST_PREFIX}/include/boost/python.hpp"
# rm -rf "${BOOST_PREFIX}/include/boost/python"
# cd $CURRENT_DIR
# git clone https://github.com/apache/thrift
# cd thrift
# git checkout 0.21.0
# Source_DIR=$(pwd)
# mkdir thrit-prefix
# export THRIFT_PREFIX=$Source_DIR/thrit-prefix
# export BOOST_ROOT=${BOOST_PREFIX}
# export ZLIB_ROOT=/usr
# export LIBEVENT_ROOT=/usr
# export OPENSSL_ROOT=/usr
# export OPENSSL_ROOT_DIR=/usr
# ./bootstrap.sh
# echo "Configuring thrift-cpp installation..."
# ./configure --prefix=$THRIFT_PREFIX \
#     --with-python=no \
#     --with-py3=no \
#     --with-ruby=no \
#     --with-java=no \
#     --with-kotlin=no \
#     --with-erlang=no \
#     --with-nodejs=no \
#     --with-c_glib=no \
#     --with-haxe=no \
#     --with-rs=no \
#     --with-cpp=yes \
#     --with-PACKAGE=yes \
#     --with-zlib=$ZLIB_ROOT \
#     --with-libevent=$LIBEVENT_ROOT \
#     --with-boost=$BOOST_ROOT \
#     --with-openssl=$OPENSSL_ROOT \
#     --enable-tests=no \
#     --enable-tutorial=no
# echo "Compiling the source code for thrift-cpp..."
# make -j$(nproc)
# echo  "Installing thrift_cpp..."
# cd $CURRENT_DIR
# git clone https://github.com/grpc/grpc
# cd grpc
# git checkout v1.68.0
# git submodule update --init
# mkdir grpc-prefix
# export GRPC_PREFIX=$(pwd)/grpc-prefix
# AR=`which ar`
# RANLIB=`which ranlib`
# PROTOC_BIN=$LIBPROTO_INSTALL/bin/protoc
# PROTOBUF_SRC=$LIBPROTO_INSTALL
# export CMAKE_PREFIX_PATH="$C_ARES_PREFIX;$RE2_PREFIX;$LIBPROTO_INSTALL"
# export LD_LIBRARY_PATH=$LIBPROTO_INSTALL/lib64:${LD_LIBRARY_PATH}
# target_platform=$(uname)-$(uname -m)
# if [[ "${target_platform}" == osx* ]]; then
#   export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=14"
#   export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"
# mkdir -p build-cpp
# pushd build-cpp
# echo "Running cmake to configure the build for grpc-cpp...."
# cmake ${CMAKE_ARGS} ..  \
#       -GNinja \
#      -DBUILD_SHARED_LIBS=ON \
#       -DCMAKE_BUILD_TYPE=Release \
#       -DCMAKE_INSTALL_PREFIX=$GRPC_PREFIX \
#       -DgRPC_CARES_PROVIDER="package" \
#       -DgRPC_GFLAGS_PROVIDER="package" \
#       -DgRPC_PROTOBUF_PROVIDER="package" \
#       -DProtobuf_ROOT=$PROTOBUF_SRC \
#       -DgRPC_SSL_PROVIDER="package" \
#       -DgRPC_ZLIB_PROVIDER="package" \
#       -DgRPC_ABSL_PROVIDER="package" \
#       -DgRPC_RE2_PROVIDER="package" \
#       -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
#       -DCMAKE_AR=${AR} \
#       -DCMAKE_RANLIB=${RANLIB} \
#       -DCMAKE_VERBOSE_MAKEFILE=ON \
#       -DProtobuf_PROTOC_EXECUTABLE=$PROTOC_BIN
# echo  "Installing grpc_cpp..."
# ninja install -v
# popd
# cd $CURRENT_DIR
# cd grpc
# git checkout v1.70.0
# git submodule update --init --recursive
# python3 -m pip install pytest hypothesis build six
# python3 -m pip install "coverage>=4.0" "cython>=0.29.8,<3.0.0" "wheel>=0.29"
# GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 python3 -m pip install -e .
# cd $CURRENT_DIR
# git clone https://github.com/OpenMathLib/OpenBLAS
# cd OpenBLAS
# git checkout v0.3.29
# git submodule update --init
# PREFIX=local/openblas
# declare -a build_opts
# LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
# export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
# unset CFLAGS
# export USE_OPENMP=1
# build_opts+=(USE_OPENMP=${USE_OPENMP})
# export PREFIX=${PREFIX}
# if [ ! -z "$FFLAGS" ]; then
#     export FFLAGS="${FFLAGS/-fopenmp/ }"
#     export FFLAGS="${FFLAGS} -frecursive"
#     export LAPACK_FFLAGS="${FFLAGS}"
# export PLATFORM=$(uname -m)
# build_opts+=(BINARY="64")
# build_opts+=(DYNAMIC_ARCH=1)
# build_opts+=(TARGET="POWER9")
# BUILD_BFLOAT16=1
# build_opts+=(INTERFACE64=0)
# build_opts+=(SYMBOLSUFFIX="")
# build_opts+=(NO_LAPACK=0)
# build_opts+=(USE_THREAD=1)
# build_opts+=(NUM_THREADS=8)
# build_opts+=(NO_AFFINITY=1)
# echo "Build OpenBLAS...."
# make -j8 ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${PREFIX}
# echo "Install OpenBLAS..."
# CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${PREFIX}" ${build_opts[@]}
# OpenBLASInstallPATH=$(pwd)/$PREFIX
# OpenBLASConfigFile=$(find . -name OpenBLASConfig.cmake)
# OpenBLASPCFile=$(find . -name openblas.pc)
# sed -i "/OpenBLAS_INCLUDE_DIRS/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
# sed -i "/OpenBLAS_LIBRARIES/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
# sed -i "s|libdir=local/openblas/lib|libdir=${OpenBLASInstallPATH}/lib|" ${OpenBLASPCFile}
# sed -i "s|includedir=local/openblas/include|includedir=${OpenBLASInstallPATH}/include|" ${OpenBLASPCFile}
# export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib"
# export PKG_CONFIG_PATH="$OpenBLASInstallPATH/lib/pkgconfig:${PKG_CONFIG_PATH}"
# cd $CURRENT_DIR
# git clone https://github.com/apache/arrow
# cd arrow
# git checkout apache-arrow-20.0.0
# git submodule update --init
# mkdir pyarrow_prefix
# export PYARROW_PREFIX=$(pwd)/pyarrow_prefix
# export ARROW_HOME=$PYARROW_PREFIX
# export target_platform=$(uname)-$(uname -m)
# export CXX=$(which g++)
# export CMAKE_PREFIX_PATH=$C_ARES_PREFIX:$LIBPROTO_INSTALL:$RE2_PREFIX:$GRPC_PREFIX:$ORC_PREFIX:$BOOST_PREFIX:${UTF8PROC_PREFIX}:$THRIFT_PREFIX:$SNAPPY_PREFIX:/usr
# export LD_LIBRARY_PATH=$GRPC_PREFIX/lib:$LIBPROTO_INSTALL/lib64
# mkdir cpp/build
# pushd cpp/build
# EXTRA_CMAKE_ARGS=""
# if [ "$(uname)" == "Linux" ]; then
#   SYSTEM_INCLUDES=$(echo | ${CXX} -E -Wp,-v -xc++ - 2>&1 | grep '^ ' | awk '{print "-isystem;" substr($1, 1)}' | tr '\n' ';')
#   EXTRA_CMAKE_ARGS=" -DARROW_GANDIVA_PC_CXX_FLAGS=${SYSTEM_INCLUDES}"
#   sed -ie 's;"--with-jemalloc-prefix\=je_arrow_";"--with-jemalloc-prefix\=je_arrow_" "--with-lg-page\=16";g' ../cmake_modules/ThirdpartyToolchain.cmake
# if [ "${build_type}" = "cuda" ]; then
#   if [[ -z "${CUDA_HOME+x}" ]]
#         echo "cuda version=${cudatoolkit} CUDA_HOME=$CUDA_HOME"
#         CUDA_GDB_EXECUTABLE=$(which cuda-gdb || exit 0)
#         if [[ -n "$CUDA_GDB_EXECUTABLE" ]]
#             CUDA_HOME=$(dirname $(dirname $CUDA_GDB_EXECUTABLE))
#             echo "Cannot determine CUDA_HOME: cuda-gdb not in PATH"
#             return 1
#   EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_CUDA=ON -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} -DCMAKE_LIBRARY_PATH=${CUDA_HOME}/lib64/stubs"
#   EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_CUDA=OFF"
# EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_GANDIVA=OFF"
# export BOOST_ROOT="${BOOST_PREFIX}"
# export Boost_ROOT="${BOOST_PREFIX}"
# export CXXFLAGS="-I$${BOOST_PREFIX}/include -I${THRIFT_PREFIX}/include"
# if [[ "${target_platform}" == "Linux-x86_64" ]]; then
#   EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_SIMD_LEVEL=SSE4_2"
# if [[ "${target_platform}" == "Linux-ppc64le" ]]; then
#   EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_ALTIVEC=ON"
# if [[ "${target_platform}" != "Linux-s390x" ]]; then
#   EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_USE_LD_GOLD=ON"
# export AR=$(which ar)
# export RANLIB=$(which ranlib)
# echo "Running cmake to configure the build for pyarrow..."
# cmake \
#     -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
#     -DARROW_BOOST_USE_SHARED=ON \
#     -DARROW_BUILD_BENCHMARKS=OFF \
#     -DARROW_BUILD_STATIC=OFF \
#     -DARROW_BUILD_TESTS=OFF \
#     -DARROW_BUILD_UTILITIES=OFF \
#     -DBUILD_SHARED_LIBS=ON \
#     -DARROW_DATASET=ON \
#     -DARROW_DEPENDENCY_SOURCE=SYSTEM \
#     -DARROW_FLIGHT=ON \
#     -DARROW_HDFS=ON \
#     -DARROW_JEMALLOC=ON \
#     -DARROW_MIMALLOC=ON \
#     -DARROW_ORC=ON \
#     -DARROW_PACKAGE_PREFIX=$PYARROW_PREFIX \
#     -DARROW_PARQUET=ON \
#     -DARROW_PYTHON=ON \
#     -DARROW_S3=OFF \
#     -DARROW_WITH_BROTLI=ON \
#     -DARROW_WITH_BZ2=ON \
#     -DARROW_WITH_LZ4=ON \
#     -DARROW_WITH_SNAPPY=ON \
#     -DARROW_WITH_ZLIB=ON \
#     -DARROW_WITH_ZSTD=ON \
#     -DARROW_WITH_THRIFT=ON \
#     -DCMAKE_BUILD_TYPE=release \
#     -DCMAKE_INSTALL_LIBDIR=lib \
#     -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
#     -DPYTHON_EXECUTABLE=python \
#     -DPython3_EXECUTABLE=python \
#     -DProtobuf_PROTOC_EXECUTABLE=${LIBPROTO_INSTALL}/bin/protoc \
#     -DORC_INCLUDE_DIR=${ORC_PREFIX}/include \
#     -DgRPC_DIR=${GRPC_PREFIX} \
#     -DBoost_DIR=${BOOST_PREFIX} \
#     -DBoost_INCLUDE_DIR=${BOOST_PREFIX}/include/ \
#     -Dutf8proc_LIB=${UTF8PROC_PREFIX}/lib/libutf8proc.so ${UTF8PROC_PREFIX}/lib/libutf8proc.so.2 ${UTF8PROC_PREFIX}/lib/libutf8proc.so.2.4.1 \
#     -Dutf8proc_INCLUDE_DIR=${UTF8PROC_PREFIX}/include \
#     -DCMAKE_AR=${AR} \
#     -DCMAKE_RANLIB=${RANLIB} \
#     -GNinja \
#     ${EXTRA_CMAKE_ARGS} \
#     ..
# echo "Installing pyarrow...."
# ninja install
# popd
# cd $CURRENT_DIR
# echo "Installing prerequisite for arrow..."
# pip install setuptools-scm Cython
# pip install numpy==2.0.2
# export PYARROW_BUNDLE_ARROW_CPP=1
# export LD_LIBRARY_PATH=${ARROW_HOME}/lib:${LD_LIBRARY_PATH}
# export build_type=cpu
# cd arrow
# export CMAKE_PREFIX_PATH=$ARROW_HOME
# export PARQUET_HOME=$ARROW_HOME
# export SETUPTOOLS_SCM_PRETEND_VERSION=$version
# export PYARROW_BUILD_TYPE=release
# export PYARROW_BUNDLE_ARROW_CPP_HEADERS=1
# export PYARROW_WITH_DATASET=1
# export PYARROW_WITH_FLIGHT=1
# export PYARROW_WITH_GANDIVA=0
# export PYARROW_WITH_HDFS=1
# export PYARROW_WITH_ORC=1
# export PYARROW_WITH_PARQUET=1
# export PYARROW_WITH_PLASMA=1
# export PYARROW_WITH_S3=0
# export PYARROW_CMAKE_GENERATOR=Ninja
# BUILD_EXT_FLAGS=""
# if [ "${build_type}" = "cuda" ]; then
#     export PYARROW_WITH_CUDA=1
#     export PYARROW_WITH_CUDA=0
# cd python
# pip install -e .
# cd $CURRENT_DIR
# git clone https://github.com/sphinx-contrib/redoc
# cd redoc
# SETUPTOOLS_SCM_PRETEND_VERSION=1.6.0 pip install .
# cd $CURRENT_DIR
# curl -LO https://www.freetds.org/files/stable/freetds-1.3.18.tar.gz
# tar -xzf freetds-1.3.18.tar.gz
# cd freetds-1.3.18
# ./configure --prefix=/usr/local --with-tdsver=7.3
# cd $CURRENT_DIR
# git clone https://github.com/confluentinc/librdkafka.git
# cd librdkafka
# ./configure
# cd $CURRENT_DIR
# wget https://ftp.gnu.org/gnu/libtool/libtool-2.4.7.tar.gz
# tar xzf libtool-2.4.7.tar.gz
# cd libtool-2.4.7
# ./configure --prefix=/usr/local
# make -j$(nproc)
# ldconfig
# cd $CURRENT_DIR
# wget https://www.aleksey.com/xmlsec/download/xmlsec1-1.3.7.tar.gz
# tar xzf xmlsec1-1.3.7.tar.gz
# cd xmlsec1-1.3.7
# ./configure --with-openssl --disable-dl --prefix=/usr/local
# ldconfig
# cd $CURRENT_DIR
# pip install uv maturin hatchling
# uv tool install -e ./dev/breeze
# uv tool install hatch
# uv tool install flit
# uv tool install cherry-picker

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
