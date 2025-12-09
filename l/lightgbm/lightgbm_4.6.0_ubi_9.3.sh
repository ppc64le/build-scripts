#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : LightGBM
# Version          : 4.6.0
# Source repo      : https://github.com/microsoft/LightGBM.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------------------------

# Variables
PACKAGE_NAME=LightGBM
PACKAGE_VERSION=${1:-v4.6.0}
PACKAGE_URL=https://github.com/microsoft/LightGBM.git
PACKAGE=LightGBM
PACKAGE_DIR=LightGBM/lightgbm-python
yum install -y python python-pip python-devel wget git make python-devel xz-devel openssl-devel zlib-devel libjpeg-devel gcc-toolset-13 cmake libevent libtool pkg-config  brotli-devel.ppc64le bzip2-devel lz4-devel glibc-devel glibc-static autoconf automake libtool krb5-devel atlas

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

SCRIPT_DIR=$(pwd)
pip install ninja setuptools 

#install cmake
wget https://cmake.org/files/v3.28/cmake-3.28.0.tar.gz
tar -zxvf cmake-3.28.0.tar.gz
cd cmake-3.28.0
./bootstrap
make
make install
cd $SCRIPT_DIR

# Installing lib like flex bison c-ares gflags rapidjson xsimd snappy libzstd
echo "-----------flex installing------------------"
wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4
./configure --prefix=/usr/local
make -j$(nproc)
make install
cd $SCRIPT_DIR

echo "-------bison installing----------------------"
wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
tar -xvf bison-3.8.2.tar.gz
cd bison-3.8.2
./configure --prefix=/usr/local
make -j$(nproc)
make install
cd $SCRIPT_DIR

echo "------------ gflags installing-------------------"
git clone https://github.com/gflags/gflags.git
cd gflags
mkdir build && cd build
cmake ..
make -j$(nproc)
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
echo "Building..."
ninja || exit 1

# Installing
echo "Installing..."
ninja install || exit 1

cd $SCRIPT_DIR

echo "----------c-areas installed-----------------------"

echo "----------------rapidjson installing------------------"
git clone https://github.com/Tencent/rapidjson.git
cd rapidjson
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
make install
cd $SCRIPT_DIR

echo "--------------xsimd installing-------------------------"
git clone https://github.com/xtensor-stack/xsimd.git
cd xsimd
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
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

cmake -DCMAKE_INSTALL_PREFIX=$SNAPPY_PREFIX \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      ..
make -j$(nproc)
make install
cd ..
cd $SCRIPT_DIR


echo "------------libzstd installing-------------------------"
git clone https://github.com/facebook/zstd.git
cd zstd
make
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
git checkout v4.25.3

LIBPROTO_DIR=$(pwd)
mkdir -p $LIBPROTO_DIR/local/libprotobuf
LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf

git submodule update --init --recursive
rm -rf ./third_party/googletest | true
rm -rf ./third_party/abseil-cpp | true

cp -r $SCRIPT_DIR/abseil-cpp ./third_party/

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

cd $SCRIPT_DIR




echo "---------------------openblas installing---------------------"

#clone and install openblas from source

git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/openblas/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/v0.3.29/g" pyproject.toml
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

cd $SCRIPT_DIR
echo "------------openblas installed--------------------"


echo "-----------------installing pyarrow----------------------"

#cloning pyarrow

git clone https://github.com/apache/arrow

cd arrow
git checkout apache-arrow-19.0.0
git submodule update --init
VERSION=19.0.0
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

cd $SCRIPT_DIR

#installing prerequisite
pip install setuptools-scm Cython
pip install numpy==2.0.2

export PYARROW_BUNDLE_ARROW_CPP=1
export LD_LIBRARY_PATH=${ARROW_HOME}/lib:${LD_LIBRARY_PATH}

export build_type=cpu
cd arrow

export CMAKE_PREFIX_PATH=$ARROW_HOME

# Build dependencies
export PARQUET_HOME=$ARROW_HOME
export SETUPTOOLS_SCM_PRETEND_VERSION=$VERSION
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

pip install .
cd ..
export LD_LIBRARY_PATH=${SNAPPY_PREFIX}/lib:${C_ARES_PREFIX}/lib:${THRIFT_PREFIX}/lib:${UTF8PROC_PREFIX}/lib:${RE2_PREFIX}/lib:${LIBPROTO_INSTALL}/lib64:${GRPC_PREFIX}/lib:${ORC_PREFIX}/lib:${OpenBLASInstallPATH}/lib
cd $SCRIPT_DIR 

#Build OpenMPI from source
echo ---------------"Downloading and building OpenMPI..."-----------------------------------------
wget https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.6.tar.gz
tar -xvf openmpi-5.0.6.tar.gz
cd openmpi-5.0.6
mkdir prefix
export PREFIX=$(pwd)/prefix

#Set environment variables for OpenMPI
export LIBRARY_PATH="/usr/lib64"

#Configure and build OpenMPI
./configure --prefix=$PREFIX \
    --disable-dependency-tracking \
    --disable-shared \
    --enable-static \
    LDFLAGS="-static"
echo "installing openmpi"
make -j$(nproc)
make install

#Set OpenMPI paths
export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH

#Navigate back to the root directory
cd $SCRIPT_DIR

echo ----------"clone lightgbm repo"---------
echo "Clone the repository..."
git clone $PACKAGE_URL
cd $PACKAGE
git submodule update --init --recursive
echo "checking out package version "
git checkout $PACKAGE_VERSION

#installing dependencies

echo "installing scipy.."
pip install scipy
echo "installling pytz..."
pip install pytz
echo "installing pytest...."
pip install pytest hypothesis
echo "installing cython.."
pip install cython
echo "installing threadpoolctl and pillow.."
pip install threadpoolctl pillow
echo "installing joblib.."
pip install joblib
echo "installing meson-python and ninja.."
pip install meson meson-python ninja
echo "installing setuptools.."
pip install setuptools setuptools_scm wheel cffi
echo "install other necessary dependency"
pip install cloudpickle psutil pybind11
echo "install matplotlib"
pip install matplotlib
echo "install pandas"
pip install pandas
echo "install scikit_build_core"
pip install scikit-build-core
echo "install scikit-learn"
pip install scikit-learn==1.5.2

echo ------"installing base package ..."-------
./build-python.sh
echo "getting into lightgbm dir ....."
cd lightgbm-python

echo "set library and other paths and again enable gcc"
source /opt/rh/gcc-toolset-13/enable
export LD_LIBRARY_PATH="${SITE_PACKAGE_PATH}/openblas/lib:${LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${SITE_PACKAGE_PATH}/openblas/lib/pkgconfig"

#setting necessary variables
export LD_LIBRARY_PATH=/thrift/thrit-prefix/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/re2/re2-prefix/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/utf8proc/utf8proc_prefix/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/protobuf/local/libprotobuf/lib64:$LD_LIBRARY_PATH

echo "Running build with MPI condition..."
python3 -m build --wheel --config-setting=cmake.define.USE_MPI=ON --outdir="$SCRIPT_DIR"

echo "installing package ..."
if ! (pip install --no-deps .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Detect Python version
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

# Detect if running in pyvenv environment
if [[ -d "/pyvenv_${PYTHON_VERSION}" ]]; then
    # Running in pyvenv environment
    echo "Detected pyvenv environment"
    export PYTHONPATH=/pyvenv_${PYTHON_VERSION}/lib64/python${PYTHON_VERSION}/site-packages:/pyvenv_${PYTHON_VERSION}/lib/python${PYTHON_VERSION}/site-packages:$PYTHONPATH

else
    # Running in non-pyvenv environment
    echo "Detected non-pyvenv environment"
    export PYTHONPATH=/usr/local/lib64/python${PYTHON_VERSION}/site-packages:/usr/local/lib/python${PYTHON_VERSION}/site-packages:$PYTHONPATH
fi

# Print PYTHONPATH for verification
echo "PYTHONPATH: $PYTHONPATH"

echo "run tests  ..."
if !(pytest ../tests -p no:warnings); then
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
