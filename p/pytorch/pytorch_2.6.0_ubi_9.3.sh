#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pytorch
# Version          : v2.6.0
# Source repo      : https://github.com/pytorch/pytorch.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Srighakollapu Sai Srivatsa <Srighakollapu.Sai.Srivatsa@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

set -e
# Variables
PACKAGE_NAME=pytorch
PACKAGE_URL=https://github.com/pytorch/pytorch.git
PACKAGE_VERSION=${1:-v2.10.0}
SCRIPT_DIR=$(pwd)

yum install -y git make wget python3.12 python3.12-devel python3.12-pip pkgconfig atlas
yum install gcc-toolset-13 -y
echo "Installed gcc-toolset"
yum install -y make libtool xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel patch ninja-build gcc-toolset-13 pkg-config pkgconf-pkg-config
dnf install -y gcc-toolset-13-libatomic-devel
echo "Installed required deps from RH"

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Ensure pkg-config can find Python (required for NumPy build with Meson)
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"

echo "Installing cmake..."
wget https://cmake.org/files/v3.31/cmake-3.31.6.tar.gz
tar -zxvf cmake-3.31.6.tar.gz
cd cmake-3.31.6
./bootstrap
make -j$(nproc)
make install
cd $SCRIPT_DIR

# -------------------- OpenBLAS --------------------
echo "---------------------openblas installing---------------------"

git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.32

make -j$(nproc) \
    TARGET=POWER9 \
    BUILD_BFLOAT16=1 \
    BINARY=64 \
    USE_OPENMP=1 \
    USE_THREAD=1 \
    NUM_THREADS=$(nproc) \
    DYNAMIC_ARCH=1 \
    INTERFACE64=0

make install PREFIX=/usr/local

export OPENBLAS_HOME=/usr/local
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}"

OpenBLASInstallPATH=/usr/local

cd $SCRIPT_DIR
echo "--------------------openblas installed-------------------------------"

# -------------------- SciPy --------------------
python3.12 -m pip install beniget==0.4.2.post1 Cython==3.0.11 gast==0.6.0 meson==1.6.0 meson-python==0.17.1 numpy==2.0.2 packaging pybind11 pyproject-metadata
python3.12 -m pip install pythran==0.17.0 setuptools==75.3.0 pooch pytest build wheel hypothesis ninja patchelf>=0.11.0

git clone https://github.com/scipy/scipy
cd scipy/
git checkout v1.15.2
git submodule update --init
python3.12 -m pip install .
cd $SCRIPT_DIR

# -------------------- Abseil --------------------
git clone https://github.com/abseil/abseil-cpp -b 20240116.2

# -------------------- Protobuf --------------------
export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v4.25.8

LIBPROTO_DIR=$(pwd)
mkdir -p $LIBPROTO_DIR/local/libprotobuf
LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf

git submodule update --init --recursive
rm -rf ./third_party/googletest || true
rm -rf ./third_party/abseil-cpp || true
cp -r $SCRIPT_DIR/abseil-cpp ./third_party/

mkdir build && cd build
echo "Building libprotobuf"
cmake -G "Ninja" \
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

echo "building libprotobuf...."
cmake --build . --verbose
echo "Installing libprotobuf...."
cmake --install .

cd ..
echo "Building protobuf"
export PROTOC=$LIBPROTO_DIR/build/protoc
export LD_LIBRARY_PATH=$SCRIPT_DIR/abseil-cpp/abseilcpp/lib:$(pwd)/build/libprotobuf.so:$LD_LIBRARY_PATH
export LIBRARY_PATH=$(pwd)/build/libprotobuf.so:$LD_LIBRARY_PATH
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

#Apply patch
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply set_cpp_to_17_v4.25.3.patch

echo "Installing protobuf...."
cd python
python3.12 -m pip install --no-build-isolation .
cd $SCRIPT_DIR

# -------------------- Rust --------------------
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

# -------------------- PyTorch --------------------
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule sync
git submodule update --init --recursive

# Fix for PyTorch 2.10
sed -i '/lintrunner ;/s/$/ and platform_machine != "ppc64le"/' requirements.txt

#Apply patch
ver=${PACKAGE_VERSION#v}

PATCH_URL="https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pytorch/pytorch_${PACKAGE_VERSION}.patch"
PATCH_FILE="pytorch_${PACKAGE_VERSION}.patch"

# Using patch file v2.9.1 for PACKAGE_VERSION >= v2.9.1 (eg: v2.10.0, v2.11.0).
# If a new patch is added eg: v2.9.1 patch is not working with v2.15.1,
# please add a similar condition below for v2.15.1.
if [[ "$(printf '%s\n' "$ver" "2.9.1" | sort -V | tail -n1)" == "$ver" ]]; then
    PATCH_URL="https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pytorch/pytorch_v2.9.1.patch"
    PATCH_FILE="pytorch_v2.9.1.patch"
fi
wget -q --spider "$PATCH_URL" && wget -q "$PATCH_URL" && git apply "$PATCH_FILE" || echo "Patch missing, skipped"


# -------------------- ENV --------------------
ARCH=`uname -p`
BUILD_NUM="1"
export OPENBLAS_INCLUDE=${OpenBLASInstallPATH}/include
export OpenBLAS_HOME=${OpenBLASInstallPATH}
export build_type="cpu"
export cpu_opt_arch="power9"
export cpu_opt_tune="power10"
export CPU_COUNT=$(nproc --all)
export _GLIBCXX_USE_CXX11_ABI=1
export C_INCLUDE_DIR="${OpenBLASInstallPATH}/include"
export CPLUS_INCLUDE_DIR="${OpenBLASInstallPATH}/include"
export LIBRARY_PATH="${OpenBLASInstallPATH}/lib:${LD_LIBRARY_PATH}"

export CPU_COUNT=$(nproc)
export CXXFLAGS="${CXXFLAGS} -mcpu=power9 -mtune=power10 -fplt"
export CFLAGS="${CFLAGS} -mcpu=power9 -mtune=power10 -fplt"

export LDFLAGS="$(echo ${LDFLAGS} | sed -e 's/-Wl\,--as-needed//')"
export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${LIBPROTO_INSTALL}/lib64 -Wl,-rpath-link,${OpenBLASInstallPATH}/lib"
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
export PYTORCH_BUILD_VERSION=${PACKAGE_VERSION#v}
export PYTORCH_BUILD_NUMBER=${BUILD_NUM}
export USE_CUDA=0
export USE_CUDNN=0
export USE_TENSORRT=0
export Protobuf_INCLUDE_DIR=${LIBPROTO_INSTALL}/include
export Protobuf_LIBRARIES=${LIBPROTO_INSTALL}/lib64
export Protobuf_LIBRARY=${LIBPROTO_INSTALL}/lib64/libprotobuf.so
export Protobuf_LITE_LIBRARY=${LIBPROTO_INSTALL}/lib64/libprotobuf-lite.so
export Protobuf_PROTOC_EXECUTABLE=${LIBPROTO_INSTALL}/bin/protoc
export PATH="/protobuf/local/libprotobuf/bin/protoc:${PATH}"
export LD_LIBRARY_PATH="/protobuf/local/libprotobuf/lib64:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/protobuf/third_party/abseil-cpp/local/abseilcpp/lib:${LD_LIBRARY_PATH}"
export CXXFLAGS="${CXXFLAGS} -mcpu=${cpu_opt_arch} -mtune=${cpu_opt_tune}"
export CFLAGS="${CFLAGS} -mcpu=${cpu_opt_arch} -mtune=${cpu_opt_tune}"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/pytorch/torch/lib/:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/pytorch/torch/lib64/:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/protobuf/local/libprotobuf/lib64/:${LD_LIBRARY_PATH}"
echo "required env variables got set"

sed -i "s/cmake/cmake==3.*/g" requirements.txt
python3.12 -m pip install -r requirements.txt

# -------------------- Build --------------------
if ! (MAX_JOBS=$(nproc) python3.12 setup.py install); then
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# -------------------- Basic Import Test --------------------
echo " Basic Import test for torch"

cd $SCRIPT_DIR

export LD_LIBRARY_PATH="${OpenBLASInstallPATH}/lib:${LD_LIBRARY_PATH}"

if ! (python3.12 -c "import torch;"); then
     echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but__Import_Fails"
     exit 2
else
     echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Import_Success"
     exit 0
fi
