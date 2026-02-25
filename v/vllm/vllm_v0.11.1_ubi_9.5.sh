#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package       : vllm
# Version       : v0.11.1
# Source repo   : https://github.com/vllm-project/vllm
# Tested on     : UBI:9.5
# Language      : Python
# Ci-Check  :     True
# Script License: Apache License 2.0
# Maintainer    : Akash Kaothalkar <akash.kaothalkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -eo pipefail

PACKAGE_NAME=vllm
PACKAGE_VERSION=${1:-v0.11.1}
PACKAGE_URL=https://github.com/vllm-project/vllm.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=vllm

TORCH_VERSION=v2.8.0
TORCHVISION_VERSION=v0.23.0
TORCH_URL=https://github.com/pytorch/pytorch.git
TORCHVISION_URL=https://github.com/pytorch/vision.git

echo "==================================================================="
echo "        vLLM FULL BUILD START (UBI 9.5 / POWER / v0.11.1)"
echo "==================================================================="

# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------
echo "-------------------- Installing OS dependencies -------------------"

yum install -y yum-utils
yum config-manager --set-enabled ubi-9-codeready-builder-rpms


yum install -y \
  git wget tar gzip xz which procps-ng yum-utils \
  --allowerasing

yum install -y \
  git make cmake gcc-toolset-13 \
  python3.12 python3.12-devel python3.12-pip \
  unzip zip wget patch \
  openssl-devel sqlite-devel \
  llvm-devel libevent-devel \
  freetype-devel gmp-devel libjpeg-turbo-devel \
  cargo libcurl-devel gcc-toolset-13-libatomic-devel libsndfile openblas-devel \
  which procps-ng yum-utils \
  --allowerasing

# -----------------------------------------------------------------------------
# Additional toolchain/runtime dependencies (POWER / UBI specific)
# -----------------------------------------------------------------------------

# libatomic required for Arrow + POWER
yum install -y gcc-toolset-13-libatomic-devel

# Autotools required to build numactl from source on UBI
yum install -y \
  autoconf \
  automake \
  libtool \
  pkgconfig \
  make \
  gcc openblas-devel

# -----------------------------------------------------------------------------
# Enable GCC toolset (CRITICAL: must stay enabled for entire script)
# -----------------------------------------------------------------------------
echo "-------------------- Enabling GCC toolset --------------------------"

source /opt/rh/gcc-toolset-13/enable


# Enforce compiler visibility for TorchInductor
export GCC_TOOLSET_ROOT=/opt/rh/gcc-toolset-13/root/usr

export CC=${GCC_TOOLSET_ROOT}/bin/gcc
export CXX=${GCC_TOOLSET_ROOT}/bin/g++

export PATH=${GCC_TOOLSET_ROOT}/bin:${PATH}
export LD_LIBRARY_PATH=${GCC_TOOLSET_ROOT}/lib64:${LD_LIBRARY_PATH}
export LIBRARY_PATH=${GCC_TOOLSET_ROOT}/lib64:${LIBRARY_PATH}
export CMAKE_PREFIX_PATH=${GCC_TOOLSET_ROOT}:${CMAKE_PREFIX_PATH}

export TORCH_INDUCTOR_CPP_COMPILER=${CXX}

# Register toolset runtime with system linker
echo "${GCC_TOOLSET_ROOT}/lib64" > /etc/ld.so.conf.d/gcc-toolset-13.conf
ldconfig

# -----------------------------------------------------------------------------
# Sanity checks
# -----------------------------------------------------------------------------

echo "Using CC = $(which gcc)"
echo "Using CXX = $(which g++)"

gcc --version
g++ --version

echo "Checking libctf resolution..."
ldd $(which g++) | grep libctf || true

echo "Checking libstdc++ resolution..."
ldd $(which g++) | grep libstdc++ || true

# Ensure gcc-toolset runtime libraries are visible
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH}
export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LIBRARY_PATH}
export CMAKE_PREFIX_PATH=/opt/rh/gcc-toolset-13/root/usr:${CMAKE_PREFIX_PATH}

export CC=/opt/rh/gcc-toolset-13/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++

# -----------------------------------------------------------------------------
# Python tooling
# -----------------------------------------------------------------------------
echo "-------------------- Upgrading Python tooling ---------------------"

python3.12 -m pip install --upgrade pip setuptools wheel

# -----------------------------------------------------------------------------
# Python binary wheels (POWER / devpi)
# -----------------------------------------------------------------------------
echo "-------------------- Installing Python dependencies ----------------"

python3.12 -m pip install \
  --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux --prefer-binary \
  "av==13.1.0" \
  "ffmpeg==7.1" \
  "lame==3.100" \
  "libprotobuf==25.4" \
  "libvpx==1.13.1" \
  "llvmlite==0.44.0" \
  "numba==0.62.0.dev0" \
  "openblas==0.3.29" \
  "opus==1.3.1" \
  "protobuf==4.25.8" \
  "scipy==1.16.0" \
  "sentencepiece==0.2.0" \
  "abseil-cpp==20240116.2" \
  certifi charset-normalizer filelock fsspec idna \
  Jinja2 MarkupSafe mpmath networkx requests \
  sympy tqdm typing_extensions urllib3 numpy

python3.12 -m pip install cmake pyyaml packaging openpyxl setuptools_scm cython

# -----------------------------------------------------------------------------
# Pillow (devpi)
# -----------------------------------------------------------------------------
echo "-------------------- Installing Pillow -----------------------------"

python3.12 -m pip install \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/ \
  pillow==11.2.1

# -----------------------------------------------------------------------------
# Resolve OpenBLAS
# -----------------------------------------------------------------------------
echo "-------------------- Resolving OpenBLAS ----------------------------"

export OpenBLAS_HOME=/usr/local/lib/python3.12/site-packages/openblas
export OpenBLAS_DIR=${OpenBLAS_HOME}
export BLAS=OpenBLAS
export LD_LIBRARY_PATH=${OpenBLAS_HOME}/lib:${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH="${OpenBLAS_HOME}/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LIBRARY_PATH="${OpenBLAS_HOME}/lib:${LIBRARY_PATH}"

# -----------------------------------------------------------------------------
# Build PyArrow 21.0.0 from source
# -----------------------------------------------------------------------------
echo "-------------------- Building PyArrow 21.0.0 -----------------------"

export PYARROW_VERSION=21.0.0

git clone --recursive https://github.com/apache/arrow.git -b apache-arrow-${PYARROW_VERSION}
cd arrow/cpp

mkdir -p build && cd build

cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DARROW_PYTHON=ON \
      -DARROW_BUILD_TESTS=OFF \
      -DARROW_JEMALLOC=ON \
      -DARROW_BUILD_STATIC=OFF \
      -DARROW_PARQUET=ON \
      ..

make -j$(nproc)
make install

echo "/usr/local/lib"   >  /etc/ld.so.conf.d/arrow.conf
echo "/usr/local/lib64" >> /etc/ld.so.conf.d/arrow.conf
ldconfig

cd ../../python

pip install -r requirements-build.txt
export PYARROW_PARALLEL=$(nproc)

python3.12 setup.py build_ext \
  --build-type=release \
  --bundle-arrow-cpp \
  bdist_wheel \
  --dist-dir ./wheelhouse

pip install wheelhouse/pyarrow-${PYARROW_VERSION}-*.whl

cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Build PyTorch 2.8.0
# -----------------------------------------------------------------------------
echo "-------------------- Building PyTorch ${TORCH_VERSION} ------------------------"

export USE_OPENMP=ON
export USE_MKLDNN=OFF
export USE_MKLDNN_CBLAS=OFF
export USE_CUDA=OFF
export CMAKE_PREFIX_PATH="${OpenBLAS_HOME}:${CMAKE_PREFIX_PATH}"

git clone --recursive ${TORCH_URL}
cd pytorch
git checkout ${TORCH_VERSION}
git submodule update --init --recursive --jobs 1

python3.12 -m pip install -r requirements.txt
ulimit -n 65536
python3.12 setup.py build_ext -j$(nproc)
python3.12 setup.py install

export LD_LIBRARY_PATH=$CURRENT_DIR/pytorch/torch/lib:$LD_LIBRARY_PATH

cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Build TorchVision
# -----------------------------------------------------------------------------
echo "-------------------- Building TorchVision --------------------------"

git clone ${TORCHVISION_URL}
cd vision
git checkout ${TORCHVISION_VERSION}
USE_FFMPEG=1 USE_JPEG=1 USE_PNG=1 python3.12 setup.py develop
cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Build numactl from source (UBI does not ship numactl-devel)
# -----------------------------------------------------------------------------

echo "-------------------- Building numactl from source ------------------"

cd ${CURRENT_DIR}

git clone https://github.com/numactl/numactl
cd numactl
git checkout v2.0.19

./autogen.sh
./configure --prefix=/usr/local
make -j$(nproc)
make install

# Register numactl libraries
echo "/usr/local/lib" > /etc/ld.so.conf.d/numactl.conf
ldconfig

# Ensure headers and libs are visible to subsequent builds
export CPLUS_INCLUDE_PATH=/usr/local/include:${CPLUS_INCLUDE_PATH}
export LIBRARY_PATH=/usr/local/lib:${LIBRARY_PATH}
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
export CMAKE_PREFIX_PATH=/usr/local:${CMAKE_PREFIX_PATH}

cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Build vLLM
# -----------------------------------------------------------------------------
echo "-------------------- Building vLLM ---------------------------------"

git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}

sed -i 's/^torch/# torch/' requirements/cpu.txt
sed -i 's/^torchvision/# torchvision/' requirements/cpu.txt
sed -i 's/^torchaudio/# torchaudio/' requirements/cpu.txt
sed -i 's/^outlines_core/# outlines_core/' requirements/common.txt
sed -i 's/^scipy/# scipy/' requirements/common.txt

python3.12 -m pip install \
  --prefer-binary \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/ \
  -r requirements/cpu.txt

python3.12 -m pip install llguidance

PIP_NO_BUILD_ISOLATION=1 \
CC=${CC} \
CXX=${CXX} \
python3.12 -m pip install xgrammar

export VLLM_TARGET_DEVICE=cpu
export MAX_JOBS=$(nproc)

python3.12 setup.py install

python3.12 setup.py bdist_wheel --dist-dir="${CURRENT_DIR}"

cd ${CURRENT_DIR}

echo "==================================================================="
echo "               vLLM WHEEL BUILT SUCCESSFULLY (v0.11.1)"
echo "==================================================================="


# 4. Run the "Hello World" example
#    Note: This attempts to download a small model (facebook/opt-125m) from HuggingFace.
#    If the build machine is offline, this step will fail.
echo "Running basic offline inference example..."

if ! python3.12 ${PACKAGE_DIR}/examples/offline_inference/basic/basic.py; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
