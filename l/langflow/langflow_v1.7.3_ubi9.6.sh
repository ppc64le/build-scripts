#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : langflow
# Version       : 1.7.3
# Source repo   : https://github.com/langflow-ai/langflow.git
# Tested on     : UBI:9.6
# Ci-Check  	: True
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=langflow
PACKAGE_VERSION=${1:-1.7.3}
SCRIPT_PACKAGE_VERSION=v1.7.3
PACKAGE_URL=https://github.com/langflow-ai/langflow.git
PACKAGE_DIR=langflow
CURRENT_DIR=$(realpath "$(pwd)")
SCRIPT_PATH=$(dirname $(realpath $0))

# -----------------------------------------------------------------------------
# Install required system packages (YUM)
# -----------------------------------------------------------------------------

yum install -y git make wget openssl-devel bzip2-devel libffi-devel zlib-devel python3.12-devel python3.12-pip cmake openblas-devel gcc-toolset-13 m4 automake libtool libjpeg-devel zlib-devel libpng-devel freetype-devel gcc-toolset-13-binutils llvm llvm-devel clang clang-devel perl libffi-devel pkgconfig zlib-devel libjpeg-turbo-devel libpng-devel freetype-devel bzip2 freetype-devel gcc-toolset-13-binutils llvm llvm-devel clang clang-devel perl libffi-devel pkgconfig zlib-devel libjpeg-turbo-devel libpng-devel freetype-devel bzip2 ninja-build lz4-devel libevent libtool pkg-config  brotli-devel.ppc64le lcms2-devel

# -----------------------------------------------------------------------------
# Enable GCC 13 (from gcc-toolset-13)
# -----------------------------------------------------------------------------

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# -----------------------------------------------------------------------------
# Install Python packages (PIP)
# -----------------------------------------------------------------------------
python3.12 -m pip install pytest anyio orjson asgi_lifespan blockbuster dotenv fastapi httpx
python3.12 -m pip install cython setuptools wheel pytest plotly
python3.12 -m pip install six numpy pandas scipy matplotlib scikit-learn graphviz ninja

# Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > sh.rustup.rs && \
sh ./sh.rustup.rs -y && export PATH=$PATH:$HOME/.cargo/bin && . "$HOME/.cargo/env"

echo " ------------------------------ Installing Swig ------------------------------ "
git clone https://github.com/nightlark/swig-pypi.git
cd swig-pypi
python3.12 -m pip install .
cd $CURRENT_DIR
echo " ------------------------------ Swig Installed Successfully ------------------------------ "


echo "----------------------bison installing---------------------------------"
wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
tar -xvf bison-3.8.2.tar.gz
cd bison-3.8.2
echo "Configuring bison installation..."
./configure --prefix=/usr/local
echo "Compiling the source code bison..."
make -j$(nproc)
echo "Installing bison..."
make install
cd $CURRENT_DIR

echo "--------------------- gflags installing --------------------------"
git clone https://github.com/gflags/gflags.git
cd gflags
mkdir build && cd build
echo "Running cmake to configure the build..."
cmake ..
echo "Compiling the source code gflags..."
make -j$(nproc)
echo "Installing gflags..."
make install
cd $CURRENT_DIR
echo " ------------------------------ gfags Installed Successfully ------------------------------ "

echo "--------------------- FAISS installing --------------------------"
cd $CURRENT_DIR
git clone https://github.com/facebookresearch/faiss.git
cd faiss
git checkout v1.9.0

# Prepare build directory
rm -rf build && mkdir build && cd build

# Setup compiler and environment variables
export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export CC=$(which gcc)
export CXX=$(which g++)

# Set correct Python vars for CMake's FindPython
export Python3_EXECUTABLE=$(which python3.12)
export Python3_INCLUDE_DIR=$(python3.12 -c "from sysconfig import get_path; print(get_path('include'))")
export Python3_LIBRARY=/usr/lib64/libpython3.12.so
export Python3_NumPy_INCLUDE_DIR=$(python3.12 -c "import numpy; print(numpy.get_include())")

# Enable GCC toolset
source /opt/rh/gcc-toolset-13/enable

# Run CMake configuration
cmake   -DFAISS_ENABLE_PYTHON=ON   -DFAISS_ENABLE_GPU=OFF   -DCMAKE_BUILD_TYPE=Release   -DPython3_EXECUTABLE=$(which python3.12)   -DPython3_INCLUDE_DIR=$(python3.12 -c "from sysconfig import get_path; print(get_path('include'))")   -DPython3_LIBRARY=/usr/lib64/libpython3.12.so   -DPython3_NumPy_INCLUDE_DIR=$(python3.12 -c "import numpy; print(numpy.get_include())")   ..

# Build FAISS Python bindings
make -j$(nproc) swigfaiss

# Build Python wheel instead of setup.py install
cd faiss/python
echo "Building Python wheel..."
python3.12 setup.py bdist_wheel
cd dist
python3.12 -m pip install *.whl
echo "FAISS 1.9.0 build and installation completed successfully!"


#echo "-------------------------------installing geos--------------------------------------"
cd $CURRENT_DIR
curl -LO https://download.osgeo.org/geos/geos-3.12.1.tar.bz2
tar -xjf geos-3.12.1.tar.bz2
cd geos-3.12.1
./configure --prefix=/usr/local
make -j$(nproc)
make install
cd $CURRENT_DIR

#echo "-------------------------------installing chroma_hnswlib--------------------------------------"
wget https://files.pythonhosted.org/packages/source/c/chroma-hnswlib/chroma_hnswlib-0.7.6.tar.gz
tar -xvzf chroma_hnswlib-0.7.6.tar.gz
cd chroma_hnswlib-0.7.6
grep -rl -- '-march=native' . | xargs sed -i 's/-march=native/-mcpu=native/g'
#python3.12 -m pip install .
python3.12 -m pip wheel . --verbose
python3.12 -m pip install *.whl
cd $CURRENT_DIR

#installing openblas
cd $CURRENT_DIR
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init
# Set build options
declare -a build_opts
# Fix ctest not automatically discovering tests
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export USE_OPENMP=1
build_opts+=(USE_OPENMP=${USE_OPENMP})
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
build_opts+=(NUM_THREADS=120)
# Disable CPU/memory affinity handling to avoid problems with NumPy and R
build_opts+=(NO_AFFINITY=1)
# Build OpenBLAS
make ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${OPENBLAS_PREFIX}
# Install OpenBLAS
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${OPENBLAS_PREFIX}" ${build_opts[@]}
export LD_LIBRARY_PATH=${OPENBLAS_PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${OPENBLAS_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
pkg-config --modversion openblas
echo "-----------------------------------------------------Installed openblas-----------------------------------------------------"

cd $CURRENT_DIR
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

export PATH=$LIBPROTOBUF_PREFIX/bin:$PATH
export PROTOC="$LIBPROTOBUF_PREFIX/bin/protoc"
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2
export LIBRARY_PATH="${LIBPROTOBUF_PREFIX}/lib64:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH=${LIBPROTOBUF_PREFIX}/lib64:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${LIBPROTOBUF_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

echo "--------------------pyarrow installing-------------------------------"
echo "Install dependencies and tools."
yum install -y  cmake zlib-devel libjpeg-devel gcc-toolset-13 cmake libevent libtool pkg-config  brotli-devel.ppc64le bzip2-devel lz4-devel
# export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
# CURRENT_DIR=$(pwd)

# Installing flex bison c-ares gflags rapidjson xsimd snappy libzstd
source /opt/rh/gcc-toolset-13/enable

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
cd $CURRENT_DIR

echo "-------bison installing----------------------"
wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
tar -xvf bison-3.8.2.tar.gz
cd bison-3.8.2
echo "Configuring bison installation..."
./configure --prefix=/usr/local
echo "Compiling the source code bison..."
make -j$(nproc)
echo "Installing bison..."
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
echo "Building c-areas..."
ninja || exit 1

# Installing
echo "Installing c-areas..."
ninja install || exit 1

cd $CURRENT_DIR

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
cd $CURRENT_DIR

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
cd $CURRENT_DIR


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
cd $CURRENT_DIR


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
cd $CURRENT_DIR



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
source /opt/rh/gcc-toolset-13/enable
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
cd $CURRENT_DIR


echo "------------thrift_cpp  installing-------------------"
git clone https://github.com/apache/thrift
cd thrift
git checkout 0.21.0
mkdir thrit-prefix
export THRIFT_PREFIX=$CURRENT_DIR/thrit-prefix

export BOOST_ROOT=${BOOST_PREFIX}
export ZLIB_ROOT=/usr
export LIBEVENT_ROOT=/usr

export _ROOT=/usr
export _ROOT_DIR=/usr

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
    --with-=$_ROOT \
    --enable-tests=no \
    --enable-tutorial=no

echo "Compiling the source code for thrift-cpp..."
make -j$(nproc)
echo  "Installing thrift_cpp..."
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

cd $CURRENT_DIR
echo "-----------------installing pyarrow----------------------"
#cloning pyarrow
git clone  https://github.com/apache/arrow
cd arrow
git checkout apache-arrow-19.0.0
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

cd $CURRENT_DIR
echo "Installing prerequisite for arrow..."
python3.12 -m pip install setuptools-scm

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
cd python
python3.12 -m pip install .

cd $CURRENT_DIR

#installing docling and other dependency for it
echo "-----------------installing leptonica----------------------"
wget https://github.com/DanBloomberg/leptonica/releases/download/1.83.1/leptonica-1.83.1.tar.gz
tar -xzf leptonica-1.83.1.tar.gz
cd leptonica-1.83.1
./configure --prefix=$HOME/leptonica
make -j$(nproc)
make install
cd $CURRENT_DIR

export PKG_CONFIG_PATH=/root/leptonica/lib/pkgconfig
export LIBLEPT_HEADERSDIR=/root/leptonica/include
echo "-----------------installed leptonica----------------------"


echo "-----------------installing tesseract----------------------"
wget https://github.com/tesseract-ocr/tesseract/archive/refs/tags/5.3.3.tar.gz
tar -xf 5.3.3.tar.gz
cd tesseract-5.3.3
./autogen.sh
./configure --prefix=/usr/local
make -j$(nproc)
make install
cd $CURRENT_DIR
echo "-----------------installed leptonica----------------------"


echo "-----------------installing libspatialindex----------------------"

wget https://github.com/libspatialindex/libspatialindex/archive/refs/tags/1.9.3.tar.gz
tar -xzf 1.9.3.tar.gz
cd libspatialindex-1.9.3
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
make install
cd $CURRENT_DIR
echo "-----------------installed libspatialindex----------------------"

echo "-----------------installing gn----------------------"
git clone https://gn.googlesource.com/gn
cd gn
python3.12 build/gen.py
ninja -C out
cp out/gn /usr/local/bin/gn
cd $CURRENT_DIR
echo "-----------------installed gn----------------------"

echo "-----------------installing openjpeg----------------------"
git clone "https://github.com/uclouvain/openjpeg.git"
cd openjpeg
git checkout v2.5.3
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
make install
export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
ldconfig
cd $CURRENT_DIR
echo "-----------------installed openjpeg----------------------"


echo "-----------------installing pillow----------------------"
git clone https://github.com/python-pillow/Pillow
cd Pillow
git checkout 11.2.1
python3.12 -m pip wheel . --verbose
python3.12 -m pip install *.whl
cd $CURRENT_DIR
echo "-----------------installed pillow----------------------"


echo "-----------------installing opencv-python----------------------"
git clone --recursive https://github.com/opencv/opencv-python.git
cd opencv-python
git checkout 86
git submodule sync
git submodule update --init --recursive opencv
cd opencv
wget https://raw.githubusercontent.com/ppc64le/build-scripts/55c9df7b6128877196079f99eb13e0f0b9b621c9/d/docling/opencv_docling_v2.36.0.patch
git apply opencv_docling_v2.36.0.patch
cd ..
export ENABLE_HEADLESS=1
python3.12 -m pip wheel . --verbose
python3.12 -m pip install *.whl
cd $CURRENT_DIR
echo "-----------------installed opencv----------------------"


echo "-----------------installing pytorch----------------------"
export PYTORCH_BUILD_VERSION=2.3.0
git clone https://github.com/pytorch/pytorch
cd pytorch
git checkout v2.3.0
python3.12 -m pip install -r requirements.txt
git submodule sync
git submodule update --init --recursive
export PYTORCH_BUILD_NUMBER=1
python3.12 setup.py bdist_wheel
python3.12 -m pip install dist/*.whl
cd $CURRENT_DIR
echo "-----------------installed pytorch----------------------"


echo "-----------------installing pypdfium2----------------------"
git clone https://github.com/pypdfium2-team/pypdfium2.git
yum install -y libatomic gcc-toolset-13-libatomic-devel
cd pypdfium2
git checkout 35a88d21450eb395e023ca280c9f4c855ec9684d
python3.12 ./setupsrc/pypdfium2_setup/build_native.py --compiler gcc
sed -i 's#7191#6996#g' ./setupsrc/pypdfium2_setup/build_native.py
python3.12 ./setupsrc/pypdfium2_setup/build_native.py --compiler gcc
PDFIUM_PLATFORM="sourcebuild" python3.12 -m pip wheel . --verbose
python3.12 -m pip install *.whl
cd $CURRENT_DIR
echo "-----------------installed pypdfium2----------------------"


echo "-----------------installing th----------------------"
git clone https://github.com/torch/torch7
cd torch7
git checkout 814ea4a
mkdir th_build
cd th_build
cmake ../lib/TH
make
make install
cd $CURRENT_DIR
echo "-----------------installed th----------------------"


echo "-----------------installing vision----------------------"
git clone https://github.com/pytorch/vision.git
cd vision
git checkout v0.16.0
python3.12 setup.py bdist_wheel
python3.12 -m pip install dist/*.whl
cd $CURRENT_DIR
echo "-----------------installed vision----------------------"

echo "-----------------installing sikit-image----------------------"
yum install -y gcc gcc-c++ make python python-devel libtool sqlite-devel xz zlib-devel  bzip2-devel libffi-devel libevent-devel libjpeg-turbo-devel gcc-gfortran openblas openblas-devel libgomp
git clone https://github.com/scikit-image/scikit-image
cd scikit-image
git checkout v0.25.2
python3.12 -m pip install -r requirements.txt
python3.12  -m pip install -r requirements/build.txt
python3.12 -m pip install --upgrade pip
python3.12 -m pip install -e .
cd $CURRENT_DIR

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
echo "-----------------installed scikit-image----------------------"

# Install tree-sitter dependencies (Java and TypeScript)
# -----------------------------------------------------------------------------
echo "--- Installing tree-sitter dependencies ---"
git clone https://github.com/tree-sitter/tree-sitter-java.git
cd tree-sitter-java && make && make install
python3.12 -m pip install .
cd ..

git clone https://github.com/tree-sitter/tree-sitter-typescript.git
cd tree-sitter-typescript && make && make install
python3.12 -m pip install .
cd ..

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
echo "--- tree-sitter installed successfully ---"

# -----------------------------------------------------------------------------
# Install grpcio from source with proper environment setup
# -----------------------------------------------------------------------------
echo "--- Installing grpcio ---"
rm -rf grpc
yum install -y python3.12 python3.12-devel python3.12-pip openssl openssl-devel git gcc-toolset-13 gcc-toolset-13-gcc-c++

git clone https://github.com/grpc/grpc.git
cd grpc
git checkout v1.76.0
git submodule update --init --recursive

python3.12 -m pip install setuptools coverage cython protobuf==4.25.8 wheel cmake==3.*

export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_WITH_CYTHON=1
export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:${PATH}"

# Install the package
python3.12 -m pip install . --no-build-isolation
python3.12 -m pip install grpcio_status==1.76.0 grpcio_tools==1.76.0 grpcio_health_checking==1.76.0 --no-build-isolation
echo "--- grpcio installed successfully ---"

echo "-----------------installing docling----------------------"
git clone https://github.com/docling-project/docling
cd docling
git checkout v2.36.1
wget https://raw.githubusercontent.com/ppc64le/build-scripts/55c9df7b6128877196079f99eb13e0f0b9b621c9/d/docling/docling_v2.36.0.patch
git apply docling_v2.36.0.patch
python3.12 -m build --wheel
python3.12 -m pip install dist/*.whl
cd $CURRENT_DIR
echo "-----------------installed docling----------------------"


echo "-----------------installing duckdb----------------------"
git clone https://github.com/duckdb/duckdb-python.git
cd duckdb-python
git submodule update --init --recursive
python3.12 -m pip install .
cd $CURRENT_DIR
echo "-----------------installed duckdb----------------------"


echo "-----------------installing qdrant-client----------------------"
git clone https://github.com/qdrant/qdrant-client.git
cd qdrant-client
python3.12 -m pip install --prefer-binary grpcio==1.71.0 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python3.12 -m pip install --prefer-binary onnxruntime==1.21.0 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python3.12 -m build
python3.12 -m pip install dist/qdrant_client-*.whl
cd $CURRENT_DIR
echo "-----------------installed qdrant-client----------------------"


echo "-----------------installing sqlite3----------------------"
wget https://sqlite.org/2023/sqlite-autoconf-3430100.tar.gz
tar -xvf sqlite-autoconf-3430100.tar.gz
cd sqlite-autoconf-3430100
./configure --prefix=/usr/local
make
make install
cd $CURRENT_DIR
echo "-----------------installed sqlite3----------------------"

echo "-----------------installing fastavro----------------------"
git clone https://github.com/fastavro/fastavro.git
cd fastavro
sed -i '/from cpython.long cimport PyLong_AS_LONG/d' fastavro/_logical_writers.pyx
sed -i '5a\
cdef extern from "Python.h":\
    long PyLong_AsLong(object)\
' fastavro/_logical_writers.pyx
sed -i 's/PyLong_AS_LONG(/PyLong_AsLong(/g' fastavro/_logical_writers.pyx
python3.12 -m pip install --upgrade pip setuptools wheel cython
python3.12 -m build
python3.12 -m pip install dist/*.whl
cd $CURRENT_DIR
echo "-----------------installed fastavro----------------------"

#install pckg
# -----------------------------------------------------------------------------
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sh ./sh.rustup.rs -y && export PATH=$PATH:$HOME/.cargo/bin && . "$HOME/.cargo/env"

python3.12 -m pip install maturin
python3.12 -m pip install beautifulsoup4==4.12.3 google-api-python-client==2.154.0 "google-search-results>=2.4.1,<3.0.0" certifi==2024.8.30 "filelock>=3.18.0" "structlog>=25.4.0" fake-useragent==1.5.1 MarkupSafe==3.0.2 wikipedia==1.4.0 json_repair==0.30.3 kubernetes==31.0.0 networkx==3.4.2
python3.12 -m pip install chromadb==0.5.23 --no-deps
python3.12 -m pip install langflow-base~=0.7.3 --no-deps
python3.12 -m pip install "langchain-chroma>=0.1.4,<0.2.0" --no-deps
python3.12 -m pip install langchain==0.3.23 langchain-community~=0.3.21 langchain-cohere==0.3.3 langchain-anthropic==0.3.14 langchain-astradb~=0.6.0 langchain-groq==0.2.1 langchain-mistralai==0.2.3  langchain-aws==0.2.7 langchain-unstructured==0.1.5 langchain-mongodb==0.2.0 langchain-nvidia-ai-endpoints==0.3.8 langchain-google-calendar-tools==0.0.1 langchain-elasticsearch==0.3.0 langchain-ollama==0.2.1 langchain-sambanova==0.1.0 "langchain-ibm>=0.3.8"
python3.12 -m pip install langchain-google-genai==2.0.6 --no-deps
python3.12 -m pip install "langchain-openai>=0.2.12" langchain-aws==0.2.7 langchain-nvidia-ai-endpoints==0.3.8 langchain-unstructured==0.1.5 langchain-google-calendar-tools==0.0.1 langchain-graph-retriever==0.6.1

python3.12 -m pip install "langchain-google-vertexai>=2.0.7,<3.0.0" --no-deps
python3.12 -m pip install langchain-google-community==2.0.3 --no-deps
python3.12 -m pip install "langchain-openai>=0.2.12" --no-deps
python3.12 -m pip install weaviate-client==4.10.2 --no-deps
python3.12 -m pip install langchain-pinecone>=0.2.8 --no-deps
python3.12 -m pip install smolagents==1.8.0 --no-deps
python3.12 -m pip install fastavro --no-deps
python3.12 -m pip install datasets --no-deps
python3.12 -m pip install qianfan==0.3.5 --no-deps
python3.12 -m pip install "astra-assistants[tools]>=2.2.13" --no-deps
python3.12 -m pip install  pgvector==0.3.6 elasticsearch==8.16.0 opensearch-py==2.8.0 "supabase>=2.6.0,<3.0.0" pymongo==4.10.1 "redis>=5.2.1" "sqlalchemy[aiosqlite]>=2.0.38,<3.0.0" duckduckgo_search==7.2.1 yfinance==0.2.50 --prefer-binary --extra-index-url="https://wheels.developerfirst.ibm.com/ppc64le/linux"
python3.12 -m pip install "pydantic-ai>=0.0.19" --no-deps
python3.12 -m pip install transformers~=4.56.1 numexpr==2.10.2 "fastparquet>=2024.11.0" "openai>=1.68.2" "cleanlab-tlm>=1.1.2" dspy-ai==2.5.41 --prefer-binary --extra-index-url="https://wheels.developerfirst.ibm.com/ppc64le/linux"
python3.12 -m pip install boto3==1.34.162 assemblyai==0.35.1 "twelvelabs>=0.4.7" "ibm-watsonx-ai>=1.3.1" "arize-phoenix-otel>=0.6.1" "litellm>=1.60.2,<2.0.0" "mcp>=1.10.1"
python3.12 -m pip install "huggingface-hub[inference]>=0.23.2,<1.0.0" --no-deps
python3.12 -m pip install langfuse==2.53.9 "langsmith>=0.3.42,<1.0.0" "openinference-instrumentation-langchain>=0.1.29" "opik>=1.6.3" mem0ai==0.1.34 "traceloop-sdk>=0.43.1"
python3.12 -m pip install langwatch
python3.12 -m pip install "aiofile>=3.9.0,<4.0.0" "needle-python>=0.4.0" sseclient-py==1.8.0 jq==1.8.0 lark==1.2.2 composio==0.8.5 composio-langchain==0.8.5 atlassian-python-api==3.41.16 jigsawstack==0.2.7 spider-client==0.1.24 "scrapegraph-py>=1.12.0"
python3.12 -m pip install google-cloud-bigquery --no-deps
python3.12 -m pip install google-cloud respx faker youtube-transcript-api baidubce gitpython markdown pytube metaphor_python pytest-asyncio
python3.12 -m pip install hatchling
# -----------------------------------------------------------------------------
# install langflow
# -----------------------------------------------------------------------------
# Updating faiss-cpu version to match custom build (GitHub tag v1.9.0)
# Reason: PyPI uses .post suffix, but we built from official source tag v1.9.0
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch
# sed -i '/faiss-cpu==1.9.0.post1/s/^/#/' pyproject.toml
if ! python3.12 -m pip install . --no-deps ; then
    echo "------------------$PACKAGE_NAME:Build_Fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi
# Set environment variables
export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH

# Langflow’s test suite cannot run without its full environment — DB, auth, and service setup are required.
# Imports trigger ServiceManager initialization, so most tests fail unless the backend is fully configured.
# Run basic import test

if ! python3.12 -c "import langflow"; then
    echo "------------------$PACKAGE_NAME:Install_success_but_import_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail |  Install_success_but_import_Fails"
    exit 2
else
    echo "-----------------$PACKAGE_NAME:Install_&_import_success----------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Install_and_Import_Success"
    exit 0
fi
