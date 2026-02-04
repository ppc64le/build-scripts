#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyarrow
# Version       : apache-arrow-20.0.0
# Source repo   : https://github.com/apache/arrow
# Tested on     : UBI:9.6
# Language      : Python, C
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
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
PACKAGE_VERSION=${1:-apache-arrow-20.0.0}
PACKAGE_URL=https://github.com/apache/arrow
version=$(echo "$PACKAGE_VERSION" | sed 's/^apache-arrow-//')
CURRENT_DIR="${PWD}"

echo "Install dependencies and tools."
yum install -y python python-pip python-devel wget git make  python-devel xz-devel openssl-devel cmake zlib-devel libjpeg-devel gcc-toolset-13 cmake libevent libtool pkg-config  brotli-devel.ppc64le bzip2-devel lz4-devel 
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

SCRIPT_DIR=$(pwd)
pip install ninja setuptools 

#install cmake
wget https://cmake.org/files/v3.28/cmake-3.28.0.tar.gz
tar -zxvf cmake-3.28.0.tar.gz
cd cmake-3.28.0
./bootstrap
echo "Compiling the source code..."
make
echo "Installing Cmake"
make install
cd ${SCRIPT_DIR}


# Installing flex bison c-ares gflags rapidjson xsimd snappy libzstd
echo "-----------flex installing------------------"
wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4
echo "Configuring flex installation..."
./configure --prefix=/usr/local
echo "Compiling the source code for flex..."
make -j$(nproc)
echo "Installing flex..."
make install
cd $SCRIPT_DIR 

echo "-------bison installing----------------------"
wget https://mirrors.cloud.tencent.com/gnu/bison/bison-3.8.2.tar.gz
tar -xvf bison-3.8.2.tar.gz
cd bison-3.8.2
echo "Configuring bison installation..."
./configure --prefix=/usr/local
echo "Compiling the source code bison..."
make -j$(nproc)
echo "Installing bison..."
make install
cd $SCRIPT_DIR

echo "------------ gflags installing-------------------"
git clone https://github.com/gflags/gflags.git
cd gflags
mkdir build && cd build
echo "Running cmake to configure the build..."
cmake ..
echo "Compiling the source code gflags..."
make -j$(nproc)
echo "Installing gflags..."
make install
cd $SCRIPT_DIR 

echo "----------Installing c-ares----------------"
#Building c-areas
git clone https://github.com/c-ares/c-ares.git
cd c-ares
git checkout cares-1_19_1


target_platform=$(uname)-$(uname -m)
AR=$(which ar)
PKG_NAME=c-ares

mkdir -p c_ares_prefix
export C_ARES_PREFIX=$(pwd)/c_ares_prefix

echo "Building ${PKG_NAME}."

# Isolate the build.
mkdir build && cd build

if [[ "$PKG_NAME" == *static ]]; then
  CARES_STATIC=ON
  CARES_SHARED=OFF
else
  CARES_STATIC=OFF
  CARES_SHARED=ON
fi

if [[ "${target_platform}" == Linux-* ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_AR=${AR}"
fi


# Generate the build files.
echo "Generating the build files..."
cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$C_ARES_PREFIX" \
      -DCARES_STATIC=${CARES_STATIC} \
      -DCARES_SHARED=${CARES_SHARED} \
      -DCARES_INSTALL=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -GNinja
      #${SRC_DIR}

# Build.
echo "Building c-areas..."
ninja || exit 1

# Installing
echo "Installing c-areas..."
ninja install || exit 1

cd $SCRIPT_DIR

echo "----------c-areas installed-----------------------"

echo "----------------rapidjson installing------------------"
git clone https://github.com/Tencent/rapidjson.git
cd rapidjson
mkdir build && cd build
echo "Running cmake to configure the build..."
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
echo "Compiling the source code for rapidjson..."
make -j$(nproc)
echo "Installing rapidjson"
make install
cd $SCRIPT_DIR 

echo "--------------xsimd installing-------------------------"
git clone https://github.com/xtensor-stack/xsimd.git
cd xsimd
mkdir build && cd build
echo "Running cmake to configure the build for xsimd.."
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
echo "Compiling the source code for xsimd..."
make -j$(nproc)
echo "Installing xsimd..."
make install
cd $SCRIPT_DIR 


echo "-----------------snappy installing----------------"
git clone https://github.com/google/snappy.git
cd snappy
git submodule update --init --recursive

mkdir -p local/snappy
export SNAPPY_PREFIX=$(pwd)/local/snappy
mkdir build
cd build
echo "Running cmake to configure the build for snappy..."
cmake -DCMAKE_INSTALL_PREFIX=$SNAPPY_PREFIX \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      ..
echo "Compiling the source code for snappy..."
make -j$(nproc)
echo "Installing snappy..."
make install
cd ..
cd $SCRIPT_DIR 


echo "------------libzstd installing-------------------------"
git clone https://github.com/facebook/zstd.git
cd zstd

echo "Compiling the source code for libzstd..."
make
echo "Installing libzstd..."
make install
export ZSTD_HOME=/usr/local
export CMAKE_PREFIX_PATH=$ZSTD_HOME
export LD_LIBRARY_PATH=$ZSTD_HOME/lib64:$LD_LIBRARY_PATH
cd $SCRIPT_DIR

#Installing re2,orc utf8proc,boost_cpp,thrift_cpp,abseil_cpp,libprotobuf, grpc_cpp,openblas as dependencies


#re2 install from sosurce
echo "------------ re2 installing-------------------"

git clone http://github.com/google/re2
cd re2
git checkout 2022-04-01

git submodule update --init

mkdir re2-prefix

export RE2_PREFIX=$(pwd)/re2-prefix

export CPU_COUNT=`nproc`

mkdir build-cmake
pushd build-cmake

echo "Running cmake to configure the build for re2..."
cmake ${CMAKE_ARGS} -GNinja \
  -DCMAKE_PREFIX_PATH=$RE2_PREFIX \
  -DCMAKE_INSTALL_PREFIX="${RE2_PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DENABLE_TESTING=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  ..
echo "Installing re2..."
  ninja -v install
  popd
echo "Running make shared-install......"
make -j "${CPU_COUNT}" prefix=${RE2_PREFIX} shared-install
cd $SCRIPT_DIR 



echo "------------ utf8proc installing-------------------"

git clone https://github.com/JuliaStrings/utf8proc.git
cd utf8proc
git submodule update --init
git checkout v2.6.1

mkdir utf8proc_prefix
export UTF8PROC_PREFIX=$(pwd)/utf8proc_prefix

# Create build directory
mkdir build
cd build
echo "Running cmake to configure the build for utf8proc..."
# Run cmake to configure the build
cmake -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_INSTALL_PREFIX="${UTF8PROC_PREFIX}" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=1 \
  -DBUILD_SHARED_LIBS=1 \
  ..
echo  "Build and install utf8proc"
cmake --build .

echo "Installing utf8proc ..."
cmake --build . --target install
cd $SCRIPT_DIR 

echo "------------ abseil_cpp cloning-------------------"

ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"


git clone $ABSEIL_URL -b $ABSEIL_VERSION


echo "------------ libprotobuf installing-------------------"

export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

#Build libprotobuf
git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v4.25.8

LIBPROTO_DIR=$(pwd)
mkdir -p $LIBPROTO_DIR/local/libprotobuf
LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf

git submodule update --init --recursive
rm -rf ./third_party/googletest | true
rm -rf ./third_party/abseil-cpp | true

cp -r $SCRIPT_DIR/abseil-cpp ./third_party/

mkdir build
cd build
echo "Running cmake to configure the build for libprotobuf..."
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
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..
echo  "Building libprotobuf..."
cmake --build . --verbose
echo  "Installing libprotobuf..."
cmake --install .
cd $SCRIPT_DIR 

echo "------------ orc installing-------------------"

git clone https://github.com/apache/orc
cd orc
git checkout v2.0.3


wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/orc/orc.patch
git apply orc.patch

mkdir orc_prefix
export ORC_PREFIX=$(pwd)/orc_prefix

mkdir -p build
cd build

export PROTOBUF_PREFIX=$LIBPROTO_INSTALL
export CMAKE_PREFIX_PATH=$LIBPROTO_INSTALL
export LD_LIBRARY_PATH=$LIBPROTO_INSTALL/lib64

export CC=$(which gcc)
export CXX=$(which g++)
export GCC=$CC
export GXX=$CXX

export HOST=$(uname)-$(uname -m)
export HOST=$(uname)-$(uname -m)

CPPFLAGS="${CPPFLAGS} -Wl,-rpath,$VIRTUAL_ENV_PATH/**/lib"


declare -a _CMAKE_EXTRA_CONFIG
if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 ]]; then
    _CMAKE_EXTRA_CONFIG+=(-DHAS_PRE_1970_EXITCODE=0)
    _CMAKE_EXTRA_CONFIG+=(-DHAS_PRE_1970_EXITCODE__TRYRUN_OUTPUT=)
    _CMAKE_EXTRA_CONFIG+=(-DHAS_POST_2038_EXITCODE=0)
    _CMAKE_EXTRA_CONFIG+=(-DHAS_POST_2038_EXITCODE__TRYRUN_OUTPUT=)
fi
if [[ ${HOST} =~ .*darwin.* ]]; then
    _CMAKE_EXTRA_CONFIG+=(-DCMAKE_AR=${AR})
    _CMAKE_EXTRA_CONFIG+=(-DCMAKE_RANLIB=${RANLIB})
    _CMAKE_EXTRA_CONFIG+=(-DCMAKE_LINKER=${LD})
fi
if [[ ${HOST} =~ .*Linux.* ]]; then
    CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"
    # I hate you so much CMake.
    LIBPTHREAD=$(find ${PREFIX} -name "libpthread.so")
    _CMAKE_EXTRA_CONFIG+=(-DPTHREAD_LIBRARY=${LIBPTHREAD})
fi

CPPFLAGS="${CPPFLAGS} -Wl,-rpath,$VIRTUAL_ENV_PATH/**/lib"
echo "Running cmake to configure the build for orc..."
cmake ${CMAKE_ARGS} \
    -DCMAKE_PREFIX_PATH=$ORC_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_JAVA=False \
    -DLZ4_HOME=/usr \
    -DZLIB_HOME=/usr \
    -DZSTD_HOME=/usr/local \
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
    -DProtobuf_ROOT=$PROTOBUF_PREFIX \
    -DPROTOBUF_HOME=$PROTOBUF_PREFIX \
    -DPROTOBUF_EXECUTABLE=$PROTOBUF_PREFIX/bin/protoc \
    -DSNAPPY_HOME=$SNAPPY_PREFIX \
    -DBUILD_LIBHDFSPP=NO \
    -DBUILD_CPP_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX=$ORC_PREFIX \
    -DCMAKE_C_COMPILER=$(type -p ${CC})     \
    -DCMAKE_CXX_COMPILER=$(type -p ${CXX})  \
    -DCMAKE_C_FLAGS="$CFLAGS"  \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-unused-parameter" \
    "${_CMAKE_EXTRA_CONFIG[@]}" \
    -GNinja ..

ninja
echo  "Installing orc..."
ninja install

cd $SCRIPT_DIR


echo "-----------------boost_cpp installing-----------------------"

git clone https://github.com/boostorg/boost
cd boost
git checkout boost-1.81.0
git submodule update --init

mkdir Boost_prefix
export BOOST_PREFIX=$(pwd)/Boost_prefix

INCLUDE_PATH="${BOOST_PREFIX}/include"
LIBRARY_PATH="${BOOST_PREFIX}/lib"

export CC=$(which gcc)
export CXX=$(which g++)
export target_platform=$(uname)-$(uname -m)
CXXFLAGS="${CXXFLAGS} -fPIC"
TOOLSET=gcc

 # http://www.boost.org/build/doc/html/bbv2/tasks/crosscompile.html
cat <<EOF > tools/build/example/site-config.jam
using ${TOOLSET} : : ${CXX} ;
EOF

LINKFLAGS="${LINKFLAGS} -L${LIBRARY_PATH}"

CXXFLAGS="$(echo ${CXXFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' |sed 's/ -mtune=[^ ]*//g')" \
CFLAGS="$(echo ${CFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' |sed 's/ -mtune=[^ ]*//g')" \
    CXX=${CXX_FOR_BUILD:-${CXX}} CC=${CC_FOR_BUILD:-${CC}} ./bootstrap.sh \
    --prefix="${BOOST_PREFIX}" \
    --without-libraries=python \
    --with-toolset=${TOOLSET} \
    --with-icu="${BOOST_PREFIX}" || (cat bootstrap.log; exit 1)
	 ADDRESS_MODEL=64
    ARCHITECTURE=power
	ABI="sysv"
	 BINARY_FORMAT="elf"

	 export CPU_COUNT=$(nproc)

echo " Building and installing Boost...."
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
    toolset=${TOOLSET} \
    include="${INCLUDE_PATH}" \
    cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
    linkflags="${LINKFLAGS}" \
    --layout=system \
    -j"${CPU_COUNT}" \
    install

# Remove Python headers as we don't build Boost.Python.
rm "${BOOST_PREFIX}/include/boost/python.hpp"
rm -r "${BOOST_PREFIX}/include/boost/python"
cd $SCRIPT_DIR 


echo "------------thrift_cpp  installing-------------------"

git clone https://github.com/apache/thrift
cd thrift
git checkout 0.21.0

Source_DIR=$(pwd)

mkdir thrit-prefix
export THRIFT_PREFIX=$Source_DIR/thrit-prefix

export BOOST_ROOT=${BOOST_PREFIX}
export ZLIB_ROOT=/usr
export LIBEVENT_ROOT=/usr

export OPENSSL_ROOT=/usr
export OPENSSL_ROOT_DIR=/usr

./bootstrap.sh
echo "Configuring thrift-cpp installation..."
./configure --prefix=$THRIFT_PREFIX \
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
    --with-zlib=$ZLIB_ROOT \
    --with-libevent=$LIBEVENT_ROOT \
    --with-boost=$BOOST_ROOT \
    --with-openssl=$OPENSSL_ROOT \
    --enable-tests=no \
    --enable-tutorial=no 

echo "Compiling the source code for thrift-cpp..."
make -j$(nproc)
echo  "Installing thrift_cpp..."
make install
cd $SCRIPT_DIR 

echo "------------ grpc_cpp installing-------------------"

git clone https://github.com/grpc/grpc
cd grpc
git checkout v1.68.0

git submodule update --init

mkdir grpc-prefix
export GRPC_PREFIX=$(pwd)/grpc-prefix

AR=`which ar`
RANLIB=`which ranlib`

PROTOC_BIN=$LIBPROTO_INSTALL/bin/protoc
PROTOBUF_SRC=$LIBPROTO_INSTALL

export CMAKE_PREFIX_PATH="$C_ARES_PREFIX;$RE2_PREFIX;$LIBPROTO_INSTALL"

export LD_LIBRARY_PATH=$LIBPROTO_INSTALL/lib64:${LD_LIBRARY_PATH}

target_platform=$(uname)-$(uname -m)

if [[ "${target_platform}" == osx* ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=14"
else
  export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"
fi


mkdir -p build-cpp
pushd build-cpp
echo "Running cmake to configure the build for grpc-cpp...."
cmake ${CMAKE_ARGS} ..  \
      -GNinja \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$GRPC_PREFIX \
      -DgRPC_CARES_PROVIDER="package" \
      -DgRPC_GFLAGS_PROVIDER="package" \
      -DgRPC_PROTOBUF_PROVIDER="package" \
      -DProtobuf_ROOT=$PROTOBUF_SRC \
      -DgRPC_SSL_PROVIDER="package" \
      -DgRPC_ZLIB_PROVIDER="package" \
      -DgRPC_ABSL_PROVIDER="package" \
      -DgRPC_RE2_PROVIDER="package" \
      -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
      -DCMAKE_AR=${AR} \
      -DCMAKE_RANLIB=${RANLIB} \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DProtobuf_PROTOC_EXECUTABLE=$PROTOC_BIN
echo  "Installing grpc_cpp..."
ninja install -v
popd

cd $SCRIPT_DIR

echo "---------------------openblas installing---------------------"

#clone and install openblas from source

git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init

PREFIX=local/openblas

# Set build options
declare -a build_opts
# Fix ctest not automatically discovering tests
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export USE_OPENMP=1
build_opts+=(USE_OPENMP=${USE_OPENMP})
export PREFIX=${PREFIX}

# Handle Fortran flags
if [ ! -z "$FFLAGS" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi
export PLATFORM=$(uname -m)
build_opts+=(BINARY="64")
build_opts+=(DYNAMIC_ARCH=1)
build_opts+=(TARGET="POWER9")
BUILD_BFLOAT16=1

# Placeholder for future builds that may include ILP64 variants.
build_opts+=(INTERFACE64=0)
build_opts+=(SYMBOLSUFFIX="")

# Build LAPACK
build_opts+=(NO_LAPACK=0)

# Enable threading and set the number of threads
build_opts+=(USE_THREAD=1)
build_opts+=(NUM_THREADS=8)

# Disable CPU/memory affinity handling to avoid problems with NumPy and R
build_opts+=(NO_AFFINITY=1)

echo "Build OpenBLAS...."
make -j8 ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${PREFIX}

echo "Install OpenBLAS..."
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${PREFIX}" ${build_opts[@]}
OpenBLASInstallPATH=$(pwd)/$PREFIX
OpenBLASConfigFile=$(find . -name OpenBLASConfig.cmake)
OpenBLASPCFile=$(find . -name openblas.pc)
sed -i "/OpenBLAS_INCLUDE_DIRS/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
sed -i "/OpenBLAS_LIBRARIES/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
sed -i "s|libdir=local/openblas/lib|libdir=${OpenBLASInstallPATH}/lib|" ${OpenBLASPCFile}
sed -i "s|includedir=local/openblas/include|includedir=${OpenBLASInstallPATH}/include|" ${OpenBLASPCFile}
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib"
export PKG_CONFIG_PATH="$OpenBLASInstallPATH/lib/pkgconfig:${PKG_CONFIG_PATH}"

cd $SCRIPT_DIR
echo "------------openblas installed--------------------"


echo "-----------------installing pyarrow----------------------"

#cloning pyarrow

git clone  $PACKAGE_URL

cd arrow
git checkout $PACKAGE_VERSION
git submodule update --init

mkdir pyarrow_prefix
export PYARROW_PREFIX=$(pwd)/pyarrow_prefix


export ARROW_HOME=$PYARROW_PREFIX
export target_platform=$(uname)-$(uname -m)
export CXX=$(which g++)
export CMAKE_PREFIX_PATH=$C_ARES_PREFIX:$LIBPROTO_INSTALL:$RE2_PREFIX:$GRPC_PREFIX:$ORC_PREFIX:$BOOST_PREFIX:${UTF8PROC_PREFIX}:$THRIFT_PREFIX:$SNAPPY_PREFIX:/usr
export LD_LIBRARY_PATH=$GRPC_PREFIX/lib:$LIBPROTO_INSTALL/lib64

mkdir cpp/build
pushd cpp/build

EXTRA_CMAKE_ARGS=""

# Include g++'s system headers
if [ "$(uname)" == "Linux" ]; then
  SYSTEM_INCLUDES=$(echo | ${CXX} -E -Wp,-v -xc++ - 2>&1 | grep '^ ' | awk '{print "-isystem;" substr($1, 1)}' | tr '\n' ';')
  EXTRA_CMAKE_ARGS=" -DARROW_GANDIVA_PC_CXX_FLAGS=${SYSTEM_INCLUDES}"
  sed -ie 's;"--with-jemalloc-prefix\=je_arrow_";"--with-jemalloc-prefix\=je_arrow_" "--with-lg-page\=16";g' ../cmake_modules/ThirdpartyToolchain.cmake
fi

# Enable CUDA support
if [ "${build_type}" = "cuda" ]; then
  if [[ -z "${CUDA_HOME+x}" ]]
    then
        echo "cuda version=${cudatoolkit} CUDA_HOME=$CUDA_HOME"
        CUDA_GDB_EXECUTABLE=$(which cuda-gdb || exit 0)
        if [[ -n "$CUDA_GDB_EXECUTABLE" ]]
        then
            CUDA_HOME=$(dirname $(dirname $CUDA_GDB_EXECUTABLE))
        else
            echo "Cannot determine CUDA_HOME: cuda-gdb not in PATH"
            return 1
        fi
    fi
  EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_CUDA=ON -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} -DCMAKE_LIBRARY_PATH=${CUDA_HOME}/lib64/stubs"
else
  EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_CUDA=OFF"
fi
# Disable Gandiva
EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_GANDIVA=OFF"

export BOOST_ROOT="${BOOST_PREFIX}"
export Boost_ROOT="${BOOST_PREFIX}"

export CXXFLAGS="-I$${BOOST_PREFIX}/include -I${THRIFT_PREFIX}/include"

#SIMD Settings
if [[ "${target_platform}" == "Linux-x86_64" ]]; then
  EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_SIMD_LEVEL=SSE4_2"
fi
if [[ "${target_platform}" == "Linux-ppc64le" ]]; then
  EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_ALTIVEC=ON"
fi
if [[ "${target_platform}" != "Linux-s390x" ]]; then
  EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_USE_LD_GOLD=ON"
fi

export AR=$(which ar)
export RANLIB=$(which ranlib)
echo "Running cmake to configure the build for pyarrow..."
cmake \
    -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
    -DARROW_BOOST_USE_SHARED=ON \
    -DARROW_BUILD_BENCHMARKS=OFF \
    -DARROW_BUILD_STATIC=OFF \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_BUILD_UTILITIES=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DARROW_DATASET=ON \
    -DARROW_DEPENDENCY_SOURCE=SYSTEM \
    -DARROW_FLIGHT=ON \
    -DARROW_HDFS=ON \
    -DARROW_JEMALLOC=ON \
    -DARROW_MIMALLOC=ON \
    -DARROW_ORC=ON \
    -DARROW_PACKAGE_PREFIX=$PYARROW_PREFIX \
    -DARROW_PARQUET=ON \
    -DARROW_PYTHON=ON \
    -DARROW_S3=OFF \
    -DARROW_WITH_BROTLI=ON \
    -DARROW_WITH_BZ2=ON \
    -DARROW_WITH_LZ4=ON \
    -DARROW_WITH_SNAPPY=ON \
    -DARROW_WITH_ZLIB=ON \
    -DARROW_WITH_ZSTD=ON \
    -DARROW_WITH_THRIFT=ON \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
    -DPYTHON_EXECUTABLE=python \
    -DPython3_EXECUTABLE=python \
    -DProtobuf_PROTOC_EXECUTABLE=${LIBPROTO_INSTALL}/bin/protoc \
    -DORC_INCLUDE_DIR=${ORC_PREFIX}/include \
    -DgRPC_DIR=${GRPC_PREFIX} \
    -DBoost_DIR=${BOOST_PREFIX} \
    -DBoost_INCLUDE_DIR=${BOOST_PREFIX}/include/ \
    -Dutf8proc_LIB=${UTF8PROC_PREFIX}/lib/libutf8proc.so ${UTF8PROC_PREFIX}/lib/libutf8proc.so.2 ${UTF8PROC_PREFIX}/lib/libutf8proc.so.2.4.1 \
    -Dutf8proc_INCLUDE_DIR=${UTF8PROC_PREFIX}/include \
    -DCMAKE_AR=${AR} \
    -DCMAKE_RANLIB=${RANLIB} \
    -GNinja \
    ${EXTRA_CMAKE_ARGS} \
    ..

echo "Installing pyarrow...."
ninja install
popd

cd $SCRIPT_DIR

echo "Installing prerequisite for arrow..."
pip install setuptools-scm "Cython>=3"
pip install numpy==1.26.4 pandas==2.0.3


export PYARROW_BUNDLE_ARROW_CPP=1
export LD_LIBRARY_PATH=${ARROW_HOME}/lib:${LD_LIBRARY_PATH}

export build_type=cpu
cd arrow

export CMAKE_PREFIX_PATH=$ARROW_HOME

# Build dependencies
export PARQUET_HOME=$ARROW_HOME
export SETUPTOOLS_SCM_PRETEND_VERSION=$version
export PYARROW_BUILD_TYPE=release
export PYARROW_BUNDLE_ARROW_CPP_HEADERS=1
export PYARROW_WITH_DATASET=1
export PYARROW_WITH_FLIGHT=1
# Disable Gandiva
export PYARROW_WITH_GANDIVA=0
export PYARROW_WITH_HDFS=1
export PYARROW_WITH_ORC=1
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_PLASMA=1
export PYARROW_WITH_S3=0
export PYARROW_CMAKE_GENERATOR=Ninja
BUILD_EXT_FLAGS=""

# Enable CUDA support
if [ "${build_type}" = "cuda" ]; then
    export PYARROW_WITH_CUDA=1
else
    export PYARROW_WITH_CUDA=0
fi

export LD_LIBRARY_PATH=${CURRENT_DIR}/pyarrow_prefix/lib/:$LD_LIBRARY_PATH

cd python

if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Creating the wheel in the build script.Because When using the wrapper script, 
# the wheel file is generated with an unexpected version, e.g., 
# 'pyarrow-19.0.1.dev0+ga8a979a41.d20250414-cp312-cp312-linux_ppc64le.whl'
# This is because when the wheel is built using the command:
# python -m build --wheel --no-isolation --outdir="$SCRIPT_DIR/"
# If we using 'python3 setup.py bdist_wheel --dist-dir="$SCRIPT_DIR/"' produces a wheel with the expected naming format.
pip install wheel
echo "Creating wheel....."
python3 setup.py bdist_wheel --dist-dir="$SCRIPT_DIR/"

echo "testing pyarrow...."
cd ..
export LD_LIBRARY_PATH=${SNAPPY_PREFIX}/lib:${C_ARES_PREFIX}/lib:${THRIFT_PREFIX}/lib:${UTF8PROC_PREFIX}/lib:${RE2_PREFIX}/lib:${LIBPROTO_INSTALL}/lib64:${GRPC_PREFIX}/lib:${ORC_PREFIX}/lib:${OpenBLASInstallPATH}/lib

pip install -r python/requirements-test.txt "pytest<9"

PYARROW_LOCATION=$(python -c "import os; import pyarrow; print(os.path.dirname(pyarrow.__file__))")
export PARQUET_TEST_DATA="$(pwd)/cpp/submodules/parquet-testing/data"
pushd testing
export ARROW_TEST_DATA=$(pwd)/data
popd

if ! python -m pytest -k "not test_foreign_buffer and not test_get_include" $PYARROW_LOCATION -vv ; then
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
