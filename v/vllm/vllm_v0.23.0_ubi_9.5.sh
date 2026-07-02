#!/bin/bash -e

# Required format:
# Package   : vllm
# Version   : v0.23.0
# Source repo   : https://github.com/vllm-project/vllm
# Tested on : UBI:9.5
# Language  : Python
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Bi Bi Rukhaiya <bibi.rukhaiya@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

set -eo pipefail

PACKAGE_NAME=vllm
PACKAGE_VERSION=v0.23.0
PACKAGE_URL=https://github.com/vllm-project/vllm.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=vllm

echo "==============================================================="
echo "       vLLM FULL BUILD START (UBI 9.5 / POWER / v0.23.0)"
echo "==============================================================="

# ===============================================================
# OS DEPENDENCIES
# ===============================================================

echo "---------------- Installing OS dependencies ----------------"

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
  glibc-headers kernel-headers glibc-devel libstdc++-devel \
  llvm-devel \
  libgomp \
  numactl \
  --allowerasing

yum install -y gcc-toolset-13-libatomic-devel

# ===============================================================
# GCC TOOLSET
# ===============================================================

echo "---------------- Enabling GCC toolset ----------------"

source /opt/rh/gcc-toolset-13/enable

export CC=gcc
export CXX=g++

gcc --version
g++ --version

# ===============================================================
# NUMACTL BUILD
# ===============================================================

echo "---------------- Building numactl ----------------"

cd ${CURRENT_DIR}

git clone https://github.com/numactl/numactl
cd numactl

git checkout v2.0.19

./autogen.sh
./configure --prefix=/usr --libdir=/usr/lib64

make -j$(nproc)
make install

ldconfig

cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Build Protobuf from source
# -----------------------------------------------------------------------------

echo "-------------------- Building Protobuf 3.20.3 from source -----------"

wget https://github.com/protocolbuffers/protobuf/releases/download/v3.20.3/protobuf-cpp-3.20.3.tar.gz
tar --no-same-owner -xzf protobuf-cpp-3.20.3.tar.gz
cd protobuf-3.20.3

./configure --prefix=/usr --libdir=/usr/lib64
make -j$(nproc)
make install
ldconfig

export Protobuf_INCLUDE_DIR=/usr/include
export Protobuf_LIBRARIES=/usr/lib64/libprotobuf.so
export Protobuf_PROTOC_EXECUTABLE=/usr/bin/protoc
export CMAKE_PREFIX_PATH=/usr:${CMAKE_PREFIX_PATH}

cd ${CURRENT_DIR}

# ===============================================================
# PYTHON TOOLING
# ===============================================================

echo "---------------- Python tooling ----------------"

python3.12 -m pip install --upgrade pip setuptools wheel

python3.12 -m pip install \
  ninja \
  cmake \
  cython \
  maturin \
  setuptools_rust \
  cffi \
  scikit-build \
  scikit-build-core \
  setuptools_scm \
  packaging

# ===============================================================
# PYTHON BASE DEPENDENCIES
# ===============================================================

echo "---------------- Python dependencies ----------------"

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

python3.12 -m pip install apache-tvm-ffi

python3.12 -m pip install \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  pillow==11.2.1 \
  grpcio==1.80.0 \
  httptools==0.7.1

python3.12 -m pip install \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  opencv-python-headless==4.13.0.92+ppc64le1

python3.12 -m pip install \
  --only-binary numpy,scipy,sentencepiece \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  numpy \
  scipy \
  protobuf \
  sentencepiece \
  tqdm \
  requests \
  sympy \
  networkx \
  Jinja2

# ===============================================================
# TORCHVISION (DevPI wheel)
# ===============================================================

echo "-------------------- Installing TorchVision ----------------------"

python3.12 -m pip install \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  torchvision==0.26.0+ppc64le1

python3.12 -c "import torchvision; print(torchvision.__version__)"

# ===============================================================
# vLLM BUILD
# ===============================================================

echo "---------------- vLLM build ----------------"

rm -rf ${PACKAGE_DIR}

git clone ${PACKAGE_URL}

cd ${PACKAGE_DIR}

git checkout ${PACKAGE_VERSION}

sed -i \
's|opencv-python-headless>=4.13.0|opencv-python-headless==4.13.0.92+ppc64le1|' \
requirements/common.txt

echo "Checking for remaining numba references..."

grep -R "numba" . || true

python3.12 -m pip install \
  --no-build-isolation \
  --only-binary numpy,scipy,sentencepiece,msgspec,cbor2,llguidance,xgrammar,numba \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  -r requirements/cpu.txt

echo "Verifying PyTorch installation..."

python3.12 -c "
import torch
print(torch.__version__)
"

export VLLM_TARGET_DEVICE=cpu
export MAX_JOBS=$(nproc)
export SETUPTOOLS_SCM_PRETEND_VERSION=${PACKAGE_VERSION#v}

source /opt/rh/gcc-toolset-13/enable

export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$LIBRARY_PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$LD_LIBRARY_PATH
export CMAKE_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$CMAKE_LIBRARY_PATH

python3.12 setup.py install

python3.12 setup.py bdist_wheel \
  --dist-dir="${CURRENT_DIR}"

python3.12 -m pip uninstall -y torchaudio || true

cd ${CURRENT_DIR}

echo "Verifying vLLM installation..."

python3.12 -c "
import vllm
print(vllm.__version__)
"

python3.12 -c "
from vllm import LLM
print('vLLM import OK')
"

# ===============================================================
# TEST
# ===============================================================

echo "---------------- Testing installed vLLM ----------------"

export VLLM_CPU_KVCACHE_SPACE=4

if ! python3.12 \
${CURRENT_DIR}/${PACKAGE_DIR}/examples/basic/offline_inference/basic.py
then
    echo "INSTALL SUCCESS BUT TEST FAILED"
    exit 2
fi

echo "==============================================================="
echo "   vLLM v0.23.0 BUILD AND TEST COMPLETED SUCCESSFULLY"
echo "==============================================================="

