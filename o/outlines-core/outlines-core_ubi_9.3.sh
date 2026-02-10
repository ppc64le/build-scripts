#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : outlines-core
# Version          : 0.1.26
# Source repo      : https://github.com/dottxt-ai/outlines-core
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------


# Variables
PACKAGE_NAME=outlines-core
PACKAGE_VERSION=${1:-0.1.26}
PACKAGE_URL=https://github.com/dottxt-ai/outlines-core
PACKAGE_DIR=outlines-core
CURRENT_DIR=$(pwd)

# Install necessary system dependencies
yum install -y git make wget python3.12 python3.12-devel python3.12-pip pkgconfig atlas \
gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc gcc-toolset-13-binutils libtool xz xz-devel zlib-devel openssl-devel bzip2-devel cmake \
libffi-devel libevent-devel patch ninja-build gcc-toolset-13-libatomic-devel libjpeg-devel brotli-devel lz4-devel



# --------------------- Enable GCC Toolset ---------------------
export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH
export LD_LIBRARY_PATH=$GCC_TOOLSET_PATH/lib64:$LD_LIBRARY_PATH

#echo "---------------Installing dependencies for pytorch-----------------------"
# --------------------- Build CMake ---------------------
wget https://cmake.org/files/v3.31/cmake-3.31.6.tar.gz
tar -zxvf cmake-3.31.6.tar.gz
cd cmake-3.31.6
./bootstrap
make -j$(nproc)
make install
cd ..

# --------------------- Build OpenBLAS ---------------------
cd $CURRENT_DIR
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init

# Set install prefix inside the OpenBLAS directory
OPENBLAS_PREFIX=$(pwd)/local
mkdir -p "${OPENBLAS_PREFIX}"
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
build_opts+=(NUM_THREADS=8)
# Disable CPU/memory affinity handling to avoid problems with NumPy and R
build_opts+=(NO_AFFINITY=1)
# Build OpenBLAS
make ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${OPENBLAS_PREFIX}
# Install OpenBLAS
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${OPENBLAS_PREFIX}" ${build_opts[@]}
export LD_LIBRARY_PATH=${OPENBLAS_PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${OPENBLAS_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
pkg-config --modversion openblas
cd $CURRENT_DIR


# --------------------- Install Python Packages ---------------------
python3.12 -m pip install -U pip
python3.12 -m pip install beniget==0.4.2.post1 Cython==3.0.11 gast==0.6.0 meson==1.6.0 meson-python==0.17.1 numpy==2.0.2 \
    packaging pybind11 pyproject-metadata pythran==0.17.0 setuptools==75.3.0 pooch pytest build wheel hypothesis ninja "patchelf>=0.11.0" setuptools-scm

# --------------------- Build SciPy ---------------------
git clone https://github.com/scipy/scipy
cd scipy
git checkout v1.15.2
git submodule update --init
python3.12 -m pip install .
cd ..

# --------------------- Build Abseil-cpp ---------------------
git clone https://github.com/abseil/abseil-cpp -b 20240116.2

# --------------------- Build Protobuf ---------------------
git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v4.25.3
git submodule update --init --recursive
rm -rf ./third_party/googletest ./third_party/abseil-cpp || true
cp -r ../abseil-cpp ./third_party/

export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

LIBPROTO_DIR=$(pwd)
mkdir -p $LIBPROTO_DIR/local/libprotobuf
LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf
mkdir build && cd build

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

cd ..

export PROTOC=$LIBPROTO_DIR/build/protoc
export LD_LIBRARY_PATH=$SCRIPT_DIR/abseil-cpp/abseilcpp/lib:$(pwd)/build/libprotobuf.so:$LD_LIBRARY_PATH
export LIBRARY_PATH=$(pwd)/build/libprotobuf.so:$LD_LIBRARY_PATH
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply set_cpp_to_17_v4.25.3.patch
cd python
python3.12 -m pip install .
cd ../..

# --------------------- Install Rust ---------------------
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

# --------------------- Build PyTorch ---------------------
git clone https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v2.6.0
git submodule sync
git submodule update --init --recursive
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pytorch/pytorch_v2.6.0.patch
git apply pytorch_v2.6.0.patch

# Set environment variables
ARCH=`uname -p`
BUILD_NUM="1"
export build_type="cpu"
export cpu_opt_arch="power9"
export cpu_opt_tune="power10"
export CPU_COUNT=$(nproc --all)
export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS"
export LDFLAGS="$(echo ${LDFLAGS} | sed -e 's/-Wl\,--as-needed//')"
export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${VIRTUAL_ENV}/lib"
export CXXFLAGS="${CXXFLAGS} -fplt"
export CFLAGS="${CFLAGS} -fplt"
export BLAS=OpenBLAS
export USE_FBGEMM=0
export USE_SYSTEM_NCCL=1
export USE_MKLDNN=0
export USE_NNPACK=0
export USE_QNNPACK=0
export USE_XNNPACK=0
export USE_PYTORCH_QNNPACK=0
export TH_BINARY_BUILD=1
export USE_LMDB=1
export USE_LEVELDB=1
export USE_NINJA=0
export USE_MPI=0
export USE_OPENMP=1
export USE_TBB=0
export BUILD_CUSTOM_PROTOBUF=OFF
export BUILD_CAFFE2=1
export PYTORCH_BUILD_VERSION=${PACKAGE_VERSION}
export PYTORCH_BUILD_NUMBER=${BUILD_NUM}
export USE_CUDA=0
export USE_CUDNN=0
export USE_TENSORRT=0
export Protobuf_INCLUDE_DIR=${LIBPROTO_INSTALL}/include
export Protobuf_LIBRARIES=${LIBPROTO_INSTALL}/lib64
export Protobuf_LIBRARY=${LIBPROTO_INSTALL}/lib64/libprotobuf.so
export Protobuf_LITE_LIBRARY=${LIBPROTO_INSTALL}/lib64/libprotobuf-lite.so
export Protobuf_PROTOC_EXECUTABLE=${LIBPROTO_INSTALL}/bin/protoc
export LD_LIBRARY_PATH=/pytorch/torch/lib64/libprotobuf.so.3.13.0.0:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/pytorch/build/lib/libprotobuf.so.3.13.0.0:$LD_LIBRARY_PATH
export PATH="/protobuf/local/libprotobuf/bin/protoc:${PATH}"
export LD_LIBRARY_PATH="/protobuf/local/libprotobuf/lib64:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/protobuf/third_party/abseil-cpp/local/abseilcpp/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH=$OPENBLAS_PREFIX/lib:$LD_LIBRARY_PATH
export CPATH=$OPENBLAS_PREFIX/include:$CPATH
export OpenBLAS_INCLUDE_DIR=$OPENBLAS_PREFIX/include
export OpenBLAS_LIB_DIR=$OPENBLAS_PREFIX/lib
export OpenBLAS_HOME=$OPENBLAS_PREFIX


# Fix CMake version requirement
sed -i "s/cmake/cmake==3.31.6/g" requirements.txt
python3.12 -m pip install -r requirements.txt

MAX_JOBS=$(nproc) python3.12 setup.py install

# --------------------- Installed PyTorch ---------------------

#---------------------- Installing dependencies for pyarrow---------------------

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

export CC=$(which gcc)
export CXX=$(which g++)
export GCC=$CC
export GXX=$CXX

export HOST=$(uname)-$(uname -m)

echo "Running cmake to configure the build for orc..."
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

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
rm -rf "${BOOST_PREFIX}/include/boost/python.hpp"
rm -rf "${BOOST_PREFIX}/include/boost/python"
cd $CURRENT_DIR 


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

echo "Cloning Apache Arrow..."
git clone https://github.com/apache/arrow.git
cd arrow
git checkout apache-arrow-19.0.0
git submodule update --init --recursive

# Set a local install prefix **inside the Arrow repo**
export ARROW_PREFIX=$(pwd)/arrow_prefix
mkdir -p $ARROW_PREFIX

echo "Building Arrow C++ with Parquet, Dataset, Acero support..."
mkdir -p cpp/build
cd cpp/build


cmake -GNinja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${ARROW_PREFIX} \
  -DBUILD_SHARED_LIBS=ON \
  -DARROW_BUILD_TESTS=OFF \
  -DARROW_COMPUTE=ON \
  -DARROW_PARQUET=ON \
  -DARROW_DATASET=ON \
  -DARROW_ACERO=ON \
  -DARROW_PYTHON=ON \
  -DARROW_WITH_ZLIB=ON \
  -DARROW_WITH_BZ2=ON \
  -DARROW_WITH_LZ4=ON \
  -DARROW_WITH_ZSTD=ON \
  -DARROW_WITH_SNAPPY=ON \
  -DARROW_SIMD_LEVEL=NONE \
  ..

ninja install

echo "Building PyArrow..."
cd ../../python

export ARROW_HOME=${ARROW_PREFIX}
export LD_LIBRARY_PATH=${ARROW_PREFIX}/lib:$LD_LIBRARY_PATH
export CPATH=${ARROW_PREFIX}/include:$CPATH
export SETUPTOOLS_SCM_PRETEND_VERSION=${VERSION_NUM}
export PYARROW_BUNDLE_ARROW_CPP=1
export PYARROW_BUNDLE_ARROW_CPP_HEADERS=1
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_DATASET=1
export PYARROW_WITH_ACERO=1
export PYARROW_WITH_HDFS=0
export PYARROW_WITH_S3=0
export PYARROW_WITH_ORC=0
export PYARROW_WITH_GANDIVA=0
export PYARROW_WITH_PLASMA=0
export PYARROW_WITH_FLIGHT=0
export PYARROW_WITH_CUDA=0

export CMAKE_PREFIX_PATH=${ARROW_HOME}:${CMAKE_PREFIX_PATH}
export ArrowCompute_DIR=${ARROW_HOME}/lib/cmake/ArrowCompute
export Arrow_DIR=${ARROW_HOME}/lib/cmake/Arrow


python3.12 setup.py install

echo "-------------------Installed Pyarrow-------------------------"


cd $CURRENT_DIR
git clone -b $PACKAGE_VERSION $PACKAGE_URL
cd $PACKAGE_NAME

export LD_LIBRARY_PATH=$OPENBLAS_PREFIX/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="${RE2_PREFIX}/lib:$LD_LIBRARY_PATH"

python3.12 -m pip install setuptools pytest pydantic pytest-cov pandas
python3.12 -m pip install sentencepiece --no-build-isolation
python3.12 -m pip install datasets==2.14.7 --no-build-isolation --no-deps
python3.12 -m pip install "multiprocess==0.70.15"
python3.12 -m pip install "xxhash==3.4.1"
python3.12 -m pip install "dill==0.3.7" "fsspec==2023.10.0" aiohttp pyarrow-hotfix
python3.12 -m pip install "transformers==4.39.2"



#install
if ! (python3.12 -m pip install -e .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi


#run tests
if !(pytest -W ignore::FutureWarning); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
