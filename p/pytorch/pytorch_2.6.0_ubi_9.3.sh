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

PACKAGE_NAME=pytorch
PACKAGE_URL=https://github.com/pytorch/pytorch.git
PACKAGE_VERSION=${1:-v2.10.0}
SCRIPT_DIR=$(pwd)

echo "Installing dependencies..."
yum install -y git make wget python3.12 python3.12-devel python3.12-pip pkgconfig atlas
yum install -y gcc-toolset-13
yum install -y make libtool xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel patch ninja-build pkg-config pkgconf-pkg-config
dnf install -y gcc-toolset-13-libatomic-devel jq

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"

# -------------------- CMake --------------------
echo "Installing CMake..."
wget https://cmake.org/files/v3.31/cmake-3.31.6.tar.gz
tar -xzf cmake-3.31.6.tar.gz
cd cmake-3.31.6
./bootstrap
make -j$(nproc)
make install
cd $SCRIPT_DIR

# -------------------- OpenBLAS --------------------
echo "Installing OpenBLAS v0.3.32"
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

export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH
export OPENBLAS_HOME=/usr/local
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

cd $SCRIPT_DIR
echo "OpenBLAS installed"

# -------------------- SciPy --------------------
echo "Installing SciPy..."
python3.12 -m pip install numpy==2.0.2 Cython meson meson-python pybind11

git clone https://github.com/scipy/scipy
cd scipy
git checkout v1.15.2
git submodule update --init --recursive
python3.12 -m pip install .
cd $SCRIPT_DIR

# -------------------- Abseil --------------------
git clone https://github.com/abseil/abseil-cpp -b 20240116.2

# -------------------- Protobuf --------------------
echo "Building protobuf..."
git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v4.25.8
git submodule update --init --recursive

LIBPROTO_DIR=$(pwd)
mkdir -p build && cd build

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$LIBPROTO_DIR/install \
  -Dprotobuf_BUILD_TESTS=OFF \
  -Dprotobuf_BUILD_SHARED_LIBS=ON \
  ..

cmake --build . -j$(nproc)
cmake --install .

export LD_LIBRARY_PATH=$LIBPROTO_DIR/install/lib:$LD_LIBRARY_PATH
cd $SCRIPT_DIR

# -------------------- Rust --------------------
echo "Installing Rust..."
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

# -------------------- PyTorch --------------------
echo "Cloning PyTorch..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule sync
git submodule update --init --recursive

# Fix lintrunner issue
sed -i '/lintrunner ;/s/$/ and platform_machine != "ppc64le"/' requirements.txt

# -------------------- ENV FLAGS --------------------
export BLAS=OpenBLAS
export USE_OPENMP=1
export USE_MKLDNN=0
export USE_NNPACK=0
export USE_QNNPACK=0
export USE_XNNPACK=0
export USE_PYTORCH_QNNPACK=0
export USE_FBGEMM=0
export USE_CUDA=0
export USE_CUDNN=0
export USE_TENSORRT=0
export USE_NINJA=0
export BUILD_CUSTOM_PROTOBUF=OFF

export _GLIBCXX_USE_CXX11_ABI=1

export OPENBLAS_HOME="/usr/local"
export C_INCLUDE_DIR="$OPENBLAS_HOME/include"
export CPLUS_INCLUDE_DIR="$OPENBLAS_HOME/include"
export LIBRARY_PATH="$OPENBLAS_HOME/lib:$LD_LIBRARY_PATH"

export CPU_COUNT=$(nproc)
export MAX_JOBS=$(nproc)

# Power tuning
export CXXFLAGS="${CXXFLAGS} -mcpu=power9 -mtune=power10 -fplt"
export CFLAGS="${CFLAGS} -mcpu=power9 -mtune=power10 -fplt"

# -------------------- Install Requirements --------------------
echo "Installing PyTorch requirements..."
python3.12 -m pip install -r requirements.txt

# -------------------- Build --------------------
echo "Building PyTorch..."
if ! (MAX_JOBS=$(nproc) python3.12 setup.py install); then
    echo "Build failed"
    exit 1
fi

# -------------------- Basic Import Test --------------------
echo " Basic Import test for torch"

cd $SCRIPT_DIR

export LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:${LD_LIBRARY_PATH}"

if ! (python3.12 -c "import torch; print('Torch version:', torch.__version__)"); then
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
