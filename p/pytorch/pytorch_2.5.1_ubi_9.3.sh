#!/bin/bash -e
 
# -----------------------------------------------------------------------------
#
# Package : pytorch
# Version : v2.5.1
# Source repo : https://github.com/pytorch/pytorch.git
# Tested on : UBI:9.3
# Language : Python
# Travis-Check : True
# Script License: Apache License, Version 2 or later
# Maintainer : Shubham Garud
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
 
# Exit immediately if a command exits with a non-zero status
set -e
PACKAGE_NAME=pytorch
PACKAGE_URL=https://github.com/pytorch/pytorch.git
PACKAGE_VERSION=${1:-v2.5.1}
PACKAGE_DIR=pytorch
SCRIPT_DIR=$(pwd)

yum install -y git make cmake wget python3.12 python3.12-devel python3.12-pip pkgconfig atlas
yum install gcc-toolset-13 -y
yum install -y make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel python3.12 python3.12-devel python3.12-pip patch ninja-build gcc-toolset-13  pkg-config
dnf install -y gcc-toolset-13-libatomic-devel
PYTHON_VERSION=python$(python3.12 --version 2>&1 | cut -d ' ' -f 2 | cut -d '.' -f 1,2)
echo $PYTHON_VERSION
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
gcc --version

export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export SITE_PACKAGE_PATH="/lib/${PYTHON_VERSION}/site-packages"

#install openblas
#clone and install openblas from source

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
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib":${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH="$OpenBLASInstallPATH/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH=${PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
pkg-config --modversion openblas
cd $SCRIPT_DIR
echo "--------------------openblas installed-------------------------------"

#Building scipy
python3.12 -m pip install beniget==0.4.2.post1  Cython==3.0.11 gast==0.6.0 meson==1.6.0 meson-python==0.17.1 numpy==2.0.2 packaging pybind11 pyproject-metadata pythran==0.17.0 setuptools==75.3.0 pooch pytest build wheel hypothesis ninja patchelf>=0.11.0
git clone https://github.com/scipy/scipy
cd scipy/
git checkout v1.15.2
git submodule update --init
export SITE_PACKAGE_PATH=/usr/local/lib/python3.12/site-packages
echo "Dependency installations"
python3.12 -m pip install .

cd $SCRIPT_DIR
#Building abesil-cpp,libprotobuf and protobuf 

python3.12 -m pip install --upgrade pip setuptools wheel ninja packaging pytest

#Building abseil-cpp
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"
mkdir $SCRIPT_DIR/abseil-prefix
PREFIX=$SCRIPT_DIR/abseil-prefix

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
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DBUILD_SHARED_LIBS=ON \
    -DABSL_PROPAGATE_CXX_STD=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
   ..
cmake --build .
cmake --install .

cd $SCRIPT_DIR
cp -r  $PREFIX/* $ABSEIL_CPP/

echo "--------------------------------abseil-cpp installed----------------------"
export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

cd $SCRIPT_DIR
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

cd ..

#Build protobuf
export PROTOC=$LIBPROTO_DIR/build/protoc
export LD_LIBRARY_PATH=$SCRIPT_DIR/abseil-cpp/abseilcpp/lib:$(pwd)/build/libprotobuf.so:$LD_LIBRARY_PATH
export LIBRARY_PATH=$(pwd)/build/libprotobuf.so:$LD_LIBRARY_PATH
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

#Apply patch 
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply set_cpp_to_17_v4.25.3.patch

cd python
python3.12 -m pip install .

echo "-------------------------- libprotobuf and  protobuf installed-----------------------"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL:${LD_LIBRARY_PATH}"
cd $SCRIPT_DIR
#python3 -m pip install wheel scipy==1.15.2 ninja build pytest

curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule sync
git submodule update --init --recursive

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pytorch/pytorch_v2.5.1.patch
git apply pytorch_v2.5.1.patch

ARCH=`uname -p`
BUILD_NUM="1"
export OPENBLAS_INCLUDE=/OpenBLAS/local/openblas/include/
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib"
export SITE_PACKAGE_PATH=/usr/local/lib/python3.12/site-packages
export OpenBLAS_HOME="/usr/include/openblas"
export ppc_arch="p9"
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
export Protobuf_INCLUDE_DIR=/protobuf/local/libprotobuf/include
export Protobuf_LIBRARIES=/protobuf/local/libprotobuf/lib64
export Protobuf_LIBRARY=/protobuf/local/libprotobuf/lib64/libprotobuf.so
export Protobuf_LITE_LIBRARY=/protobuf/local/libprotobuf/lib64/libprotobuf-lite.so
export Protobuf_PROTOC_EXECUTABLE=/protobuf/local/libprotobuf/bin/protoc
export absl_DIR=/root/abseil-cpp/local/abseilcpp/lib/cmake
export LD_LIBRARY_PATH=/pytorch/torch/lib64/libprotobuf.so.3.13.0.0:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/pytorch/build/lib/libprotobuf.so.3.13.0.0:$LD_LIBRARY_PATH
export PATH="/protobuf/local/libprotobuf/bin/protoc:${PATH}"
export LD_LIBRARY_PATH="/protobuf/local/libprotobuf/lib64:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/abseil-cpp/local/abseilcpp/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/protobuf/third_party/abseil-cpp/local/abseilcpp/lib:${LD_LIBRARY_PATH}"
export CMAKE_PREFIX_PATH="${SITE_PACKAGE_PATH}"
cp -r `find ${ABSEIL_CPP} -type d -name absl` $Protobuf_INCLUDE_DIR
if ! (python3.12 -m pip install -r requirements.txt);then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! (MAX_JOBS=$(nproc) python3.12 setup.py install);then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

exit 0
#skipping test due to avoid timeout
# cd ..

# if ! (pytest pytorch/test/test_utils.py -k "not test_device_mode_ops_sparse_mm_reduce_cpu_bfloat16 and not test_device_mode_ops_sparse_mm_reduce_cpu_float16  and not test_device_mode_ops_sparse_mm_reduce_cpu_float32 and not test_device_mode_ops_sparse_mm_reduce_cpu_float64"); then
#     echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
#     exit 2
# else
#     echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
#     exit 0
# fi
