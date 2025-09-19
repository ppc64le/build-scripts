#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tensorflow-text
# Version       : v2.18.1
# Source repo   : https://github.com/tensorflow/text.git
# Tested on     : UBI 9.3
# Language      : c
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 

PACKAGE_NAME=tensorflow-text
PACKAGE_VERSION=${1:-v2.18.1}
PACKAGE_URL=https://github.com/tensorflow/text.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=text

yum install -y git make libtool wget tar openssl-devel cmake zlib-devel libjpeg-devel gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran cmake libevent-devel zlib-devel openssl-devel clang libtool  pkg-config  brotli-devel  bzip2-devel utf8proc xz bzip2-devel libffi-devel patch ninja-build
yum install -y  wget git make  python-devel xz-devel openssl-devel cmake zlib-devel libjpeg-devel gcc-toolset-13 cmake libevent libtool pkg-config  brotli-devel.ppc64le bzip2-devel lz4-devel python3.12 python3.12-devel python3.12-pip 
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$LIBRARY_PATH
export CPATH=/opt/rh/gcc-toolset-13/root/usr/include:$CPATH
GCC_BIN_DIR=$(echo "$PATH" | cut -d':' -f1)
export GCC_HOME=$(dirname "$GCC_BIN_DIR")
export CC="$GCC_BIN_DIR/gcc"
export CXX="$GCC_BIN_DIR/g++"

CURRENT_DIR=$(pwd)
mkdir -p builder/wheels
pip3.12 install ninja setuptools setuptools-scm Cython wheel 

echo "-------Installing cmake---------"
#install cmake
wget https://cmake.org/files/v3.28/cmake-3.28.0.tar.gz
tar -zxvf cmake-3.28.0.tar.gz
cd cmake-3.28.0
./bootstrap
make
make install
cd $CURRENT_DIR


echo "-----------flex installing------------------"
wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4
./configure --prefix=/usr/local
make -j$(nproc)
make install
cd $CURRENT_DIR

echo "-------bison installing----------------------"
wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
tar -xvf bison-3.8.2.tar.gz
cd bison-3.8.2
./configure --prefix=/usr/local
make -j$(nproc)
make install
cd $CURRENT_DIR

echo "------------ gflags installing-------------------"
git clone https://github.com/gflags/gflags.git
cd gflags
mkdir build && cd build
cmake ..
make -j$(nproc)
make install
cd $CURRENT_DIR 

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
echo "Building..."
ninja || exit 1

# Installing
echo "Installing..."
ninja install || exit 1

cd $CURRENT_DIR

echo "----------c-areas installed-----------------------"

echo "----------------rapidjson installing------------------"
git clone https://github.com/Tencent/rapidjson.git
cd rapidjson
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
make install
cd $CURRENT_DIR 

echo "--------------xsimd installing-------------------------"
git clone https://github.com/xtensor-stack/xsimd.git
cd xsimd
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
make install
cd $CURRENT_DIR 


echo "-----------------snappy installing----------------"
git clone https://github.com/google/snappy.git
cd snappy
git submodule update --init --recursive

mkdir -p local/snappy
export SNAPPY_PREFIX=$(pwd)/local/snappy
mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX=$SNAPPY_PREFIX \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      ..
make -j$(nproc)
make install
cd ..
cd $CURRENT_DIR 


echo "------------libzstd installing-------------------------"
git clone https://github.com/facebook/zstd.git
cd zstd
make
make install
export ZSTD_HOME=/usr/local
export CMAKE_PREFIX_PATH=$ZSTD_HOME
export LD_LIBRARY_PATH=$ZSTD_HOME/lib64:$LD_LIBRARY_PATH
cd $CURRENT_DIR

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

cmake ${CMAKE_ARGS} -GNinja \
  -DCMAKE_PREFIX_PATH=$RE2_PREFIX \
  -DCMAKE_INSTALL_PREFIX="${RE2_PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DENABLE_TESTING=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  ..

  ninja -v install
  popd
make -j "${CPU_COUNT}" prefix=${RE2_PREFIX} shared-install
cd $CURRENT_DIR 



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

# Run cmake to configure the build
cmake -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_INSTALL_PREFIX="${UTF8PROC_PREFIX}" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=1 \
  -DBUILD_SHARED_LIBS=1 \
  ..
# Build and install
cmake --build .
cmake --build . --target install
cd $CURRENT_DIR 

echo "------------ abseil_cpp cloning-------------------"

ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"


git clone $ABSEIL_URL -b $ABSEIL_VERSION


echo "------------ libprotobuf installing-------------------"

export C_COMPILER=$CC
export CXX_COMPILER=$CXX

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

cp -r $CURRENT_DIR/abseil-cpp ./third_party/

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
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..

cmake --build . --verbose
cmake --install .
cd $CURRENT_DIR 

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

export GCC=$CC
export GXX=$CXX

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
ninja install

cd $CURRENT_DIR


echo "-----------------boost_cpp installing-----------------------"

git clone https://github.com/boostorg/boost
cd boost
git checkout boost-1.81.0
git submodule update --init

mkdir Boost_prefix
export BOOST_PREFIX=$(pwd)/Boost_prefix

INCLUDE_PATH="${BOOST_PREFIX}/include"
LIBRARY_PATH="${BOOST_PREFIX}/lib"

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
rm -rf "${BOOST_PREFIX}/include/boost/python.hpp"
rm -rf "${BOOST_PREFIX}/include/boost/python"
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

make -j$(nproc)
make install
cd $CURRENT_DIR 




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

ninja install -v
popd

cd $CURRENT_DIR


echo "---------------------openblas installing---------------------"

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

# Build OpenBLAS
make -j8 ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${PREFIX}

# Install OpenBLAS
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

cd $CURRENT_DIR
echo "------------openblas installed--------------------"

echo "Installing NumPy"
python3.12 -m pip install numpy==2.0.2

echo "-----------------installing pyarrow----------------------"

#cloning pyarrow

git clone https://github.com/apache/arrow
cd arrow
git checkout apache-arrow-19.0.0
git submodule update --init

mkdir pyarrow_prefix
export PYARROW_PREFIX=$(pwd)/pyarrow_prefix


export ARROW_HOME=$PYARROW_PREFIX
export target_platform=$(uname)-$(uname -m)
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

ninja install
popd

cd $CURRENT_DIR
export PYARROW_BUNDLE_ARROW_CPP=1
export LD_LIBRARY_PATH=${ARROW_HOME}/lib:${LD_LIBRARY_PATH}

export build_type=cpu
cd arrow

export CMAKE_PREFIX_PATH=$ARROW_HOME

# Build dependencies
export PARQUET_HOME=$ARROW_HOME
export SETUPTOOLS_SCM_PRETEND_VERSION=19.0.0
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

cd python

pip3.12 install .
cd $CURRENT_DIR


echo "------HDF5 installing-----------------------"
git clone https://github.com/HDFGroup/hdf5
cd hdf5/
git checkout hdf5-1_12_1
git submodule update --init
export HDF5_PREFIX=/install-deps/hdf5
./configure --prefix=$HDF5_PREFIX --enable-cxx --enable-fortran --with-pthread=yes \
            --enable-threadsafe --enable-build-mode=production --enable-unsupported \
            --enable-using-memchecker --enable-clear-file-buffers --with-ssl
make -j$(nproc)
make install
export LD_LIBRARY_PATH=${HDF5_PREFIX}/lib:$LD_LIBRARY_PATH
export HDF5_DIR=${HDF5_PREFIX}
cd $CURRENT_DIR

echo "----------h5py installing--------------------"
git clone https://github.com/h5py/h5py.git
cd h5py/
git checkout 3.13.0
HDF5_DIR=${HDF5_PREFIX} python3.12 -m pip install .
cd $CURRENT_DIR

echo "----------bazel installing--------------------"
yum install -y  zip java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless unzip

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

wget https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-dist.zip
mkdir -p  bazel-6.5.0
unzip bazel-6.5.0-dist.zip -d bazel-6.5.0/
cd bazel-6.5.0/
export EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash
./compile.sh
#export the path of bazel bin
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
cd $CURRENT_DIR

echo "--------------ml_dtypes installing---------------"
git clone https://github.com/jax-ml/ml_dtypes.git
cd ml_dtypes
git checkout v0.4.1
git submodule update --init

export CFLAGS="-I${ML_DIR}/include"
export CXXFLAGS="-I${ML_DIR}/include"

python3.12 -m pip install .
cd $CURRENT_DIR

echo "----------Installing patchelf from source------------"
yum install -y git autoconf automake libtool make
 
git clone https://github.com/NixOS/patchelf.git
cd patchelf
./bootstrap.sh
./configure
make -j$(nproc)
make install
ln -s /usr/local/bin/patchelf /usr/bin/patchelf
cd $CURRENT_DIR

echo "--------------Tensorflow installing------------------"

yum install -y  gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make cmake binutils 

yum install -y libffi-devel openssl-devel sqlite-devel zip rsync

INSTALL_ROOT="/install-deps"
mkdir -p $INSTALL_ROOT

export cpu_opt_arch="power9"
export cpu_opt_tune="power10"
export build_type="cpu"
echo "CPU Optimization Settings:"
echo "cpu_opt_arch=${cpu_opt_arch}"
echo "cpu_opt_tune=${cpu_opt_tune}"
echo "build_type=${build_type}"

SHLIB_EXT=".so"
WORK_DIR=$(pwd)

export TF_PYTHON_VERSION=$(python3.12 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
export HERMETIC_PYTHON_VERSION=$(python3.12 --version | awk '{print $2}' | cut -d. -f1,2)
export GCC_HOST_COMPILER_PATH=$CC

# set the variable, when grpcio fails to compile on the system. 
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true;  
export LDFLAGS="${LDFLAGS} -lrt"
export HDF5_DIR=/install-deps/hdf5
export CFLAGS="-I${HDF5_DIR}/include"
export LDFLAGS="-L${HDF5_DIR}/lib"

# clone source repository
cd $CURRENT_DIR
git clone https://github.com/tensorflow/tensorflow
cd tensorflow
git checkout v2.18.1
SRC_DIR=$(pwd)

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/tensorflow/tf_2.18.1_fix.patch
git apply tf_2.18.1_fix.patch
rm -rf tensorflow/*.bazelrc
PYTHON_BIN_PATH=$(which python3.12)
PYTHON_LIB_PATH=$($PYTHON_BIN_PATH -c 'import site; print(site.getsitepackages()[0])')
# Pick up additional variables defined from the conda build environment
export PYTHON_BIN_PATH="$PYTHON_BIN_PATH"
export USE_DEFAULT_PYTHON_LIB_PATH=1

# Build the bazelrc
BAZEL_RC_DIR=$(pwd)/tensorflow
ARCH=`uname -p`
XNNPACK_STATUS=false
NL=$'\n'
BUILD_COPT="build:opt --copt="
BUILD_HOST_COPT="build:opt --host_copt="
CPU_ARCH_FRAG="-mcpu=${cpu_opt_arch}"
CPU_ARCH_OPTION=${BUILD_COPT}${CPU_ARCH_FRAG}
CPU_ARCH_HOST_OPTION=${BUILD_HOST_COPT}${CPU_ARCH_FRAG}
CPU_TUNE_FRAG="-mtune=${cpu_opt_tune}";
CPU_TUNE_OPTION=${BUILD_COPT}${CPU_TUNE_FRAG}
CPU_TUNE_HOST_OPTION=${BUILD_HOST_COPT}${CPU_TUNE_FRAG}

USE_MMA=0

TENSORFLOW_PREFIX=/install-deps/tensorflow

cat > "$BAZEL_RC_DIR/python_configure.bazelrc" << EOF
build --action_env PYTHON_BIN_PATH="$PYTHON_BIN_PATH"
build --action_env PYTHON_LIB_PATH="$PYTHON_LIB_PATH"
build --python_path="$PYTHON_BIN_PATH"
EOF

SYSTEM_LIBS_PREFIX=$TENSORFLOW_PREFIX
cat >> $BAZEL_RC_DIR/tensorflow.bazelrc << EOF
import %workspace%/tensorflow/python_configure.bazelrc
build:xla --define with_xla_support=true
build --config=xla
${CPU_ARCH_OPTION}
${CPU_ARCH_HOST_OPTION}
${CPU_TUNE_OPTION}
${CPU_TUNE_HOST_OPTION}
${VEC_OPTIONS}
build:opt --define with_default_optimizations=true

build --action_env TF_CONFIGURE_IOS="0"
build --action_env TF_SYSTEM_LIBS="org_sqlite"
build --action_env GCC_HOME=$GCC_HOME
build --action_env RULES_PYTHON_PIP_ISOLATED="0"
build --define=PREFIX="$SYSTEM_LIBS_PREFIX"
build --define=LIBDIR="$SYSTEM_LIBS_PREFIX/lib"
build --define=INCLUDEDIR="$SYSTEM_LIBS_PREFIX/include"
build --define=tflite_with_xnnpack="$XNNPACK_STATUS"
build --copt="-DEIGEN_ALTIVEC_ENABLE_MMA_DYNAMIC_DISPATCH=$USE_MMA"
build --strip=always
build --color=yes
build --verbose_failures
build --spawn_strategy=standalone
EOF


export BUILD_TARGET="//tensorflow/tools/pip_package:wheel //tensorflow/tools/lib_package:libtensorflow //tensorflow:libtensorflow_cc${SHLIB_EXT}"

#Install
if ! (bazel --bazelrc=tensorflow/tensorflow.bazelrc build --local_cpu_resources=HOST_CPUS*0.50 --local_ram_resources=HOST_RAM*0.50 --config=opt ${BUILD_TARGET}) ; then  
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#copying .so and .a files into local/tensorflow/lib
mkdir -p $SRC_DIR/tensorflow_pkg
mkdir -p $SRC_DIR/local
find ./bazel-bin/tensorflow/tools/pip_package/wheel_house -iname "*.whl" -exec cp {} $SRC_DIR/tensorflow_pkg  \;
unzip -n $SRC_DIR/tensorflow_pkg/*.whl -d ${SRC_DIR}/local
mkdir -p ${SRC_DIR}/local/tensorflow/lib
find  ${SRC_DIR}/local/tensorflow  -type f \( -name "*.so*" -o -name "*.a" \) -exec cp {} ${SRC_DIR}/local/tensorflow/lib \;

#Build libtensorflow and libtensorflow_cc artifacts
mkdir -p $SRC_DIR/libtensorflow_extracted
tar -xzf $SRC_DIR/bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz -C $SRC_DIR/libtensorflow_extracted
mkdir -p ${SRC_DIR}/local/tensorflow/include
rsync -a  $SRC_DIR/libtensorflow_extracted/lib/*.so*  ${SRC_DIR}/local/tensorflow/lib 
cp -d -r $SRC_DIR/libtensorflow_extracted/include/* ${SRC_DIR}/local/tensorflow/include

mkdir -p $SRC_DIR/libtensorflow_cc_output/lib
mkdir -p $SRC_DIR/libtensorflow_cc_output/include
cp -d  bazel-bin/tensorflow/libtensorflow_cc.so* $SRC_DIR/libtensorflow_cc_output/lib/
cp -d  bazel-bin/tensorflow/libtensorflow_framework.so* $SRC_DIR/libtensorflow_cc_output/lib/
cp -d  $SRC_DIR/libtensorflow_cc_output/lib/libtensorflow_framework.so.2 ./libtensorflow_cc_output/lib/libtensorflow_framework.so

chmod u+w $SRC_DIR/libtensorflow_cc_output/lib/libtensorflow*


mkdir -p $SRC_DIR/libtensorflow_cc_output/include/tensorflow
rsync -r --chmod=D777,F666 --exclude '_solib*' --exclude '_virtual_includes/' --exclude 'pip_package/' --exclude 'lib_package/' --include '*/' --include '*.h' --include '*.inc' --exclude '*' bazel-bin/ $SRC_DIR/libtensorflow_cc_output/include
rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' tensorflow/cc $SRC_DIR/libtensorflow_cc_output/include/tensorflow/
rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' tensorflow/core $SRC_DIR/libtensorflow_cc_output/include/tensorflow/
rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' third_party/xla/third_party/tsl/ $SRC_DIR/libtensorflow_cc_output/include/
rsync -r --chmod=D777,F666 --include '*/' --include '*' --exclude '*.cc' third_party/ $SRC_DIR/libtensorflow_cc_output/include/tensorflow/third_party/
rsync -a $SRC_DIR/libtensorflow_cc_output/include/*  ${SRC_DIR}/local/tensorflow/include
rsync -a $SRC_DIR/libtensorflow_cc_output/lib/*.so ${SRC_DIR}/local/tensorflow/lib

mkdir -p repackged_wheel

# Pack the locally built TensorFlow files into a wheel
wheel pack local/ -d repackged_wheel
pip3.12 install $SRC_DIR/repackged_wheel/*.whl
cp -a $SRC_DIR/repackged_wheel/*.whl $CURRENT_DIR/builder/wheels
cd $CURRENT_DIR


echo "-------installing array-record--------------"
cd $CURRENT_DIR
git clone https://github.com/google/array_record
cd array_record
# array-record not tagged to use v0.6.0, used hard commit for v0.6.0
git checkout 7e299eae0db0d7bfc20f7c1e1548bf86cdbfef5e
sed -i "s/packages=find_packages()/packages=[\"array_record\", \"array_record.python\", \"array_record.beam\"]/g" setup.py
cd $CURRENT_DIR
mkdir -p build-dir/array_record
cd $CURRENT_DIR/array_record
cp -r python beam $CURRENT_DIR/build-dir/array_record
cp setup.py $CURRENT_DIR/build-dir/
cd $CURRENT_DIR/build-dir
pip3.12 install .
python3.12 setup.py bdist_wheel
cp -a dist/*.whl $CURRENT_DIR/builder/wheels
cd $CURRENT_DIR

echo "------------------Tesorflow-dataset installing-----------------------"
git clone https://github.com/tensorflow/datasets.git
cd datasets
git checkout v4.9.7
python3.12 setup.py install
cd $CURRENT_DIR

echo "----------psutils installing-----------------"
git clone https://github.com/giampaolo/psutil.git
cd psutil
git checkout release-7.0.0
pip3.12 install .
cd $CURRENT_DIR

echo "------------Tensoflow-Text installing-----------------"
PACKAGE_NAME=tensorflow-text
PACKAGE_VERSION=${1:-v2.18.1}
PACKAGE_URL=https://github.com/tensorflow/text.git
PACKAGE_DIR=text
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/tensorflow-text/0001-update-pins-and-fix-build-failures.patch
git apply 0001-update-pins-and-fix-build-failures.patch
export PATH=/bazel-6.5.0/output/:$PATH
export BAZEL_LINKLIBS=-l%:libstdc++.a
if ! sh oss_scripts/run_build.sh; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
# Install pre-requisite wheels and dependencies
echo "Build and installation completed successfully."
echo "There are no test cases available. skipping the test cases"
