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
# Maintainer       : Ira <ira.pandey1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

set -e

# Package configuration
PACKAGE_NAME=pytorch
PACKAGE_URL=https://github.com/pytorch/pytorch.git
PACKAGE_VERSION=${1:-v2.11.0}
PYTHON_VERSION=${PYTHON_VERSION:-3.12}
PACKAGE_DIR=pytorch
SCRIPT_DIR=$(pwd)

# Install system dependencies
yum install -y git make wget python3.12 python3.12-devel python3.12-pip pkgconfig atlas
yum install -y gcc-toolset-13

yum install -y make libtool xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel patch gcc-toolset-13 pkg-config pkgconf-pkg-config openblas-devel
dnf install -y gcc-toolset-13-libatomic-devel
# Install threading libraries required by CMake FindThreads
yum install -y glibc-devel glibc-headers

# Configure GCC toolset environment
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"

# Install CMake
yum install -y cmake
cd $SCRIPT_DIR

# Install OpenBLAS from IBM ppc64le wheels
python3.12 -m pip install openblas==0.3.32+ppc64le1 \
  --prefer-binary \
  --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux \
  --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux-v2026.03.31

# Install SciPy from IBM ppc64le wheels
# Install appropriate scipy version based on PYTHON_VERSION
if [ "$PYTHON_VERSION" == "3.14" ]; then
  echo "Installing scipy v1.16.1 for Python 3.14"
  python3.12 -m pip install scipy==1.16.1+ppc64le1 \
    --prefer-binary \
    --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux \
    --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux-v2026.03.31
else
  echo "Installing scipy v1.15.2 for Python $PYTHON_VERSION"
  python3.12 -m pip install scipy==1.15.2+ppc64le1 \
    --prefer-binary \
    --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux \
    --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux-v2026.03.31
fi

# Install protobuf and libprotobuf from IBM ppc64le wheels
python3.12 -m pip install protobuf==4.25.8 \
  --prefer-binary \
  --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux \
  --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux-v2026.03.31

python3.12 -m pip install libprotobuf==28.0+ppc64le1 \
  --prefer-binary \
  --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux \
  --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux-v2026.03.31

# Install Rust toolchain
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

# Clone PyTorch repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule sync
git submodule update --init --recursive

# Apply ppc64le-specific patch if available
PATCH_URL="https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pytorch/pytorch_${PACKAGE_VERSION}.patch"
PATCH_FILE="pytorch_${PACKAGE_VERSION}.patch"
wget -q --spider "$PATCH_URL" && wget -q "$PATCH_URL" && git apply "$PATCH_FILE" || echo "Patch missing, skipped"

# Build configuration
ARCH=`uname -p`
BUILD_NUM="1"

export PYTHON_SITE_PACKAGES="$(python3.12 -c 'import site; paths = site.getsitepackages() if hasattr(site, "getsitepackages") else []; print(paths[0] if paths else site.getusersitepackages())')"
export OpenBLAS_HOME="${PYTHON_SITE_PACKAGES}/openblas"
export OPENBLAS_INCLUDE="${OpenBLAS_HOME}/include"
echo "***********************************"
echo $PYTHON_SITE_PACKAGES
echo $OpenBLAS_HOME
echo $OPENBLAS_INCLUDE
echo "***********************************"

# CPU optimization settings for POWER architecture
export build_type="cpu"
export cpu_opt_arch="power9"
export cpu_opt_tune="power10"

export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS"
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

# Apply CPU architecture optimizations
export CXXFLAGS="${CXXFLAGS} -mcpu=${cpu_opt_arch} -mtune=${cpu_opt_tune}"
export CFLAGS="${CFLAGS} -mcpu=${cpu_opt_arch} -mtune=${cpu_opt_tune}"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/pytorch/torch/lib/:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/pytorch/torch/lib64/:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/protobuf/local/libprotobuf/lib64/:${LD_LIBRARY_PATH}"

# Install Python dependencies
sed -i "s/cmake/cmake==3.*/g" requirements.txt
python3.12 -m pip install -r requirements.txt

# Build and install PyTorch
echo "Building PyTorch with MAX_JOBS=${MAX_JOBS} to manage memory usage..."
if ! (MAX_JOBS=${nproc} python3.12 setup.py install); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Verify installation with basic import test
echo "Running basic import test for torch..."
cd ..
export LD_LIBRARY_PATH=${PYTHON_SITE_PACKAGES}/openblas/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/lib:$LD_LIBRARY_PATH

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
