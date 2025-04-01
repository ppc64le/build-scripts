#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyarrow
# Version       : apache-arrow-19.0.0
# Source repo   : https://github.com/apache/arrow
# Tested on     : UBI:9.3
# Language      : Python, C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y python python-pip python-devel git make  python-devel  openssl-devel cmake zlib-devel libjpeg-devel gcc-toolset-13 cmake libevent libtool flex bison  pkg-config c-ares-devel brotli-devel.ppc64le gflags-devel rapidjson-devel xsimd-devel bzip2-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

PACKAGE_NAME=pyarrow
PACKAGE_DIR=arrow
PACKAGE_VERSION=${1:-apache-arrow-19.0.0}
PACKAGE_URL=https://github.com/apache/arrow

version=19.0.0

SCRIPT_DIR=$(pwd)
PARAMETER_CONFIG_FILE=$1

pip install ninja setuptools
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


echo "------------ abseil_cpp installing-------------------"

ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"
mkdir $SCRIPT_DIR/abseil-prefix

ABSEIL_PREFIX=$SCRIPT_DIR/abseil-prefix

git clone $ABSEIL_URL -b $ABSEIL_VERSION
cd abseil-cpp

SOURCE_DIR=$(pwd)

mkdir -p $SOURCE_DIR/local/abseilcpp
ABSEIL_CPP=$SOURCE_DIR/local/abseilcpp

echo "abseil-cpp build starts"
mkdir build
cd build

cmake -G Ninja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=${ABSEIL_PREFIX} \
    -DBUILD_SHARED_LIBS=ON \
    -DABSL_PROPAGATE_CXX_STD=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
   ..
cmake --build .
cmake --install .

cd $SCRIPT_DIR
cp -r  $ABSEIL_PREFIX/* $ABSEIL_CPP/

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
    -DCMAKE_PREFIX_PATH=$ABSEIL_CPP \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..

cmake --build . --verbose
cmake --install .
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

export CMAKE_PREFIX_PATH="$PREFIX;$RE2_PREFIX;$LIBPROTO_INSTALL"


export LD_LIBRARY_PATH=$PREFIX/lib:${LD_LIBRARY_PATH}

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


echo "------------ orc installing-------------------"

git clone https://github.com/apache/orc
cd orc
git checkout v2.0.3
yum install -y snappy-devel libzstd-devel lz4-devel 

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/python-ecosystem/o/orc/orc.patch
git apply orc.patch

mkdir orc_prefix
export ORC_PREFIX=$(pwd)/orc_prefix

mkdir -p build
cd build

export PROTOBUF_PREFIX=$LIBPROTO_INSTALL
export CMAKE_PREFIX_PATH=$ABSEIL_PREFIX
export LD_LIBRARY_PATH=$ABSEIL_PREFIX/lib

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
    -DZSTD_HOME=/usr \
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
    -DProtobuf_ROOT=$PROTOBUF_PREFIX \
    -DPROTOBUF_HOME=$PROTOBUF_PREFIX \
    -DPROTOBUF_EXECUTABLE=$PROTOBUF_PREFIX/bin/protoc \
    -DSNAPPY_HOME=/usr \
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



echo "---------------------openblas installing---------------------"

#clone and install openblas from source

git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/python-ecosystem/o/openblas/pyproject.toml
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

git clone  $PACKAGE_URL

cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule update --init

mkdir pyarrow_prefix
export PYARROW_PREFIX=$(pwd)/pyarrow_prefix


export ARROW_HOME=$PYARROW_PREFIX
export target_platform=$(uname)-$(uname -m)
export CXX=$(which g++)
export CMAKE_PREFIX_PATH=$ABSEIL_PREFIX:$LIBPROTO_INSTALL:$RE2_PREFIX:$GRPC_PREFIX:$ORC_PREFIX:$BOOST_PREFIX:${UTF8PROC_PREFIX}:$THRIFT_PREFIX:/usr
export LD_LIBRARY_PATH=$ABSEIL_PREFIX/lib:$GRPC_PREFIX/lib:$LIBPROTO_INSTALL/lib64

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
    -DARROW_FLIGHT_REQUIRE_TLSCREDENTIALSOPTIONS=ON \
    -DARROW_HDFS=ON \
    -DARROW_JEMALLOC=ON \
    -DARROW_MIMALLOC=ON \
    -DARROW_ORC=ON \
    -DARROW_PACKAGE_PREFIX=$PYARROW_PREFIX \
    -DARROW_PARQUET=ON \
    -DARROW_PLASMA=ON \
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
    -DLLVM_TOOLS_BINARY_DIR=/usr/bin \
    -DPYTHON_EXECUTABLE=python \
    -DPython3_EXECUTABLE=python \
    -DProtobuf_DIR=${LIBPROTO_INSTALL} \
    -DProtobuf_LIBRARIES=${LIBPROTO_INSTALL}/lib64 \
    -DProtobuf_INCLUDE_DIR=${LIBPROTO_INSTALL}/include \
    -DProtobuf_PROTOC_EXECUTABLE=${LIBPROTO_INSTALL}/bin/protoc \
    -DORC_LIBRARIES=${ORC_PREFIX}/lib \
    -DORC_INCLUDE_DIR=${ORC_PREFIX}/include \
    -DgRPC_DIR=${GRPC_PREFIX} \
    -DGRPCPP_IMPORTED_LOCATION=${GRPC_PREFIX}/lib/ \
    -DGRPC_CPP_PLUGIN=${GRPC_PREFIX}/bin/ \
    -DBoost_DIR=${BOOST_PREFIX} \
    -DBoost_LIB=${BOOST_PREFIX}/lib/ \
    -DBoost_INCLUDE_DIR=${BOOST_PREFIX}/include/ \
    -DTHRIFT_DIR=${THRIFT_PREFIX} \
    -DTHRIFT_LIB=${THRIFT_PREFIX}/lib \
    -DTHRIFT_INCLUDE_DIR=${THRIFT_PREFIX}/include \
    -Dutf8proc_DIR=${UTF8PROC_PREFIX} \
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

if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#testing
cd ..
export LD_LIBRARY_PATH=${PYARROW_PREFIX}:${THRIFT_PREFIX}/lib:${UTF8PROC_PREFIX}/lib:${RE2_PREFIX}/lib:${LIBPROTO_INSTALL}/lib64:${GRPC_PREFIX}/lib:${ORC_PREFIX}/lib:${OpenBLASInstallPATH}/lib

pip install -r python/requirements-test.txt

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
