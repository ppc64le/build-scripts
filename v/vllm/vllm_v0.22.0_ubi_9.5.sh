#!/bin/bash -e

# Required format:
# Package	: vllm
# Version	: v0.22.0
# Source repo	: https://github.com/vllm-project/vllm
# Tested on	: UBI:9.5
# Language	: Python
# Ci-Check	: True
# Script License: Apache License 2.0
# Maintainer	: Bi Bi Rukhaiya <bibi.rukhaiya@ibm.com>
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
PACKAGE_VERSION=v0.22.0
PACKAGE_URL=https://github.com/vllm-project/vllm.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=vllm

echo "==============================================================="
echo "        vLLM FULL BUILD START (UBI 9.5 / POWER / v0.22.0)"
echo "==============================================================="

# ===============================================================
# OS DEPENDENCIES
# ===============================================================

echo "-------------------- Installing OS dependencies -------------------"

yum install -y yum-utils
yum config-manager --set-enabled ubi-9-codeready-builder-rpms

yum install -y \
  git make cmake gcc-toolset-13 gcc gcc-c++ \
  python3.12 python3.12-devel python3.12-pip \
  unzip zip wget patch bzip2 \
  openssl-devel sqlite-devel \
  freetype-devel libjpeg-turbo-devel zlib-devel \
  gmp-devel \
  cargo libcurl-devel \
  autoconf automake libtool pkgconfig \
  openblas-devel \
  glibc-headers kernel-headers glibc-devel libstdc++-devel \
  llvm-devel \
  libgomp \
  numactl \
  --allowerasing

yum install -y gcc-toolset-13-libatomic-devel

# ===============================================================
# GCC TOOLSET
# ===============================================================

echo "-------------------- Enabling GCC toolset --------------------------"

source /opt/rh/gcc-toolset-13/enable

export CC=gcc
export CXX=g++

gcc --version
g++ --version

# ===============================================================
# OPENBLAS BUILD (SOURCE)
# ===============================================================

echo "-------------------- Building OpenBLAS -----------------------------"

cd ${CURRENT_DIR}

git clone https://github.com/OpenMathLib/OpenBLAS.git
cd OpenBLAS

make TARGET=POWER10 BINARY=64 USE_OPENMP=1 DYNAMIC_ARCH=1 -j$(nproc)
make PREFIX=/usr/local install

echo "/usr/local/lib" > /etc/ld.so.conf.d/openblas.conf
ldconfig

# sanity check
pkg-config --modversion openblas || true

cd ${CURRENT_DIR}

# ===============================================================
# OPENBLAS ENV
# ===============================================================

export BLAS=OpenBLAS
export USE_OPENMP=1
export USE_MKLDNN=OFF
export USE_MKLDNN_CBLAS=OFF

export OpenBLAS_HOME=/usr/local

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}
export LIBRARY_PATH=/usr/local/lib:${LIBRARY_PATH}
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
export CMAKE_PREFIX_PATH=/usr/local:${CMAKE_PREFIX_PATH}

export C_INCLUDE_PATH=/usr/local/include:${C_INCLUDE_PATH}
export CPLUS_INCLUDE_PATH=/usr/local/include:${CPLUS_INCLUDE_PATH}

# ===============================================================
# PYTHON TOOLING
# ===============================================================

echo "-------------------- Python tooling -------------------------------"

python3.12 -m pip install --upgrade pip setuptools wheel

python3.12 -m pip install \
  ninja cmake cython maturin setuptools_rust cffi \
  scikit-build-core setuptools_scm packaging

# ===============================================================
# PYTHON BASE DEPENDENCIES
# ===============================================================

echo "-------------------- Python dependencies --------------------------"

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

python3.12 -m pip install apache-tvm-ffi

python3.12 -m pip install \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  pillow==11.2.1 grpcio==1.80.0 httptools==0.7.1

python3.12 -m pip install \
  --only-binary numpy,scipy,sentencepiece \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  numpy scipy protobuf sentencepiece tqdm requests \
  sympy networkx Jinja2

# ===============================================================
# PROTOBUF (FROM SOURCE - IF NEEDED)
# ===============================================================

echo "-------------------- Protobuf build -------------------------------"

wget https://github.com/protocolbuffers/protobuf/releases/download/v3.20.3/protobuf-cpp-3.20.3.tar.gz

tar --no-same-owner --no-same-permissions -xzf protobuf-cpp-3.20.3.tar.gz
cd protobuf-3.20.3

./configure --prefix=/usr --libdir=/usr/lib64
make -j$(nproc)
make install
ldconfig
protoc --version || true

cd ${CURRENT_DIR}

# ===============================================================
# PYTORCH (SOURCE BUILD v2.11.0)
# ===============================================================

echo "-------------------- PyTorch build -------------------------------"

git clone --recursive https://github.com/pytorch/pytorch.git
cd pytorch

git checkout v2.11.0

git describe --tags

git submodule sync
git submodule update --init --recursive

python3.12 -m pip install -r requirements.txt

python3.12 setup.py build_ext -j$(nproc)
python3.12 setup.py install

cd ${CURRENT_DIR}

echo "Verifying PyTorch installation..."
python3.12 -c "import torch; print(torch.__version__)"

echo "Verifying PyTorch installation..."
ldd $(python3.12 -c "import torch, os; print(os.path.join(torch.__path__[0], 'lib', 'libtorch_cpu.so'))") | grep openblas

echo "Verifying OpenMP linkage..."
ldd $(python3.12 -c "import torch, os; print(os.path.join(torch.__path__[0], 'lib', 'libtorch_cpu.so'))") | grep -E "omp"

# ===============================================================
# TORCHVISION (SOURCE BUILD v0.26.0)
# ===============================================================

echo "-------------------- TorchVision build ----------------------------"

git clone https://github.com/pytorch/vision.git torchvision
cd torchvision

git checkout v0.26.0

git describe --tags

python3.12 setup.py install

cd ${CURRENT_DIR}
python3.12 -c "import torchvision; print(torchvision.__version__)"

# ===============================================================
# vLLM BUILD
# ===============================================================

echo "-------------------- vLLM build ----------------------------------"

rm -rf vllm

git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}

git checkout ${PACKAGE_VERSION}

python3.12 use_existing_torch.py

# Remove numba / llvmlite dependency
find requirements -type f -exec sed -i '/^numba/d' {} \; || true
sed -i '/numba/d' pyproject.toml || true
sed -i '/llvmlite/d' pyproject.toml || true

echo "Checking for remaining numba references..."
grep -R "numba" . || true

python3.12 -m pip install --no-build-isolation \
  --only-binary numpy,scipy,sentencepiece,msgspec,cbor2 \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  -r requirements/cpu.txt

python3.12 -m pip install --no-deps llguidance xgrammar

export VLLM_TARGET_DEVICE=cpu
export MAX_JOBS=$(nproc)
export SETUPTOOLS_SCM_PRETEND_VERSION=${PACKAGE_VERSION#v}

source /opt/rh/gcc-toolset-13/enable

export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$LIBRARY_PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$LD_LIBRARY_PATH
export CMAKE_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$CMAKE_LIBRARY_PATH

python3.12 setup.py install
python3.12 setup.py bdist_wheel --dist-dir="${CURRENT_DIR}"

cd ${CURRENT_DIR}
echo "Verifying vLLM installation..."
python3.12 -c "import vllm; print(vllm.__version__)"
python3.12 -c "from vllm import LLM; print('vLLM import OK')"

echo "-------------------- Testing installed vLLM ------------------------"

export VLLM_CPU_KVCACHE_SPACE=4

if ! python3.12 ${CURRENT_DIR}/${PACKAGE_DIR}/examples/basic/offline_inference/basic.py; then
    echo "INSTALL SUCCESS BUT TEST FAILED"
    exit 2
fi

echo "==============================================================="
echo "      vLLM v0.22.0 BUILD AND TEST COMPLETED SUCCESSFULLY"
echo "==============================================================="
