#!/bin/bash -e

# Required format:
# Package	: vllm
# Version	: v0.21.0
# Source repo	: https://github.com/vllm-project/vllm
# Tested on	: UBI:9.5
# Language	: Python
# Ci-Check	: True
# Script License: Apache License 2.0
# Maintainer	: Akash Kaothalkar <akash.kaothalkar@ibm.com>
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
PACKAGE_VERSION=${1:-v0.21.0}
PACKAGE_URL=https://github.com/vllm-project/vllm.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=vllm

echo "==================================================================="
echo "        vLLM FULL BUILD START (UBI 9.5 / POWER / v0.21.0)"
echo "==================================================================="

# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------

echo "-------------------- Installing OS dependencies -------------------"

yum install -y yum-utils
yum config-manager --set-enabled ubi-9-codeready-builder-rpms

yum install -y \
  git make cmake gcc-toolset-13 \
  python3.12 python3.12-devel python3.12-pip \
  unzip zip wget patch bzip2 \
  openssl-devel sqlite-devel \
  freetype-devel gmp-devel libjpeg-turbo-devel \
  cargo libcurl-devel \
  autoconf automake libtool pkgconfig \
  openblas-devel \
  glibc-headers kernel-headers glibc-devel libstdc++-devel \
  llvm-devel \
  --allowerasing

yum install -y gcc-toolset-13-libatomic-devel

# -----------------------------------------------------------------------------
# Enable GCC toolset
# -----------------------------------------------------------------------------

echo "-------------------- Enabling GCC toolset --------------------------"

source /opt/rh/gcc-toolset-13/enable

export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH}
export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:/usr/lib64:${LIBRARY_PATH}
export CMAKE_PREFIX_PATH=/opt/rh/gcc-toolset-13/root/usr:${CMAKE_PREFIX_PATH}

export CC=gcc
export CXX=g++

gcc --version
g++ --version



# -----------------------------------------------------------------------------
# Build numactl from source
# -----------------------------------------------------------------------------

echo "-------------------- Building numactl from source ------------------"

cd ${CURRENT_DIR}

git clone https://github.com/numactl/numactl
cd numactl
git checkout v2.0.19

./autogen.sh
./configure --prefix=/usr --libdir=/usr/lib64
make -j$(nproc)
make install

# Register numactl libraries
echo "/usr/local/lib" > /etc/ld.so.conf.d/numactl.conf
ldconfig

export CPLUS_INCLUDE_PATH=/usr/local/include:${CPLUS_INCLUDE_PATH}
export LIBRARY_PATH=/usr/local/lib:${LIBRARY_PATH}
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
export CMAKE_PREFIX_PATH=/usr/local:${CMAKE_PREFIX_PATH}

cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Build Protobuf from source
# NOTE: UBI 9.5 does not have protobuf-devel in repositories, so we build from source
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

# -----------------------------------------------------------------------------
# Python tooling
# -----------------------------------------------------------------------------

echo "-------------------- Upgrading Python tooling ---------------------"

python3.12 -m pip install --upgrade pip setuptools wheel
python3.12 -m pip install \
  "setuptools==68.0.0" \
  wheel \
  ninja \
  setuptools_scm \
  packaging \
  cmake \
  cython \
  maturin \
  setuptools_rust \
  cffi \
  scikit-build-core

# -----------------------------------------------------------------------------
# Python dependencies
# -----------------------------------------------------------------------------

echo "-------------------- Installing Python dependencies ----------------"

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

# Pre-install apache-tvm-ffi before other packages that depend on it
python3.12 -m pip install apache-tvm-ffi

# Pre-install pillow with specific version to avoid build issues
python3.12 -m pip install \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  pillow==11.2.1

python3.12 -m pip install \
  --only-binary numpy,scipy,sentencepiece \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  numpy scipy protobuf sentencepiece tqdm requests \
  sympy networkx Jinja2

# -----------------------------------------------------------------------------
# Build vLLM
# -----------------------------------------------------------------------------

echo "-------------------- Building vLLM ---------------------------------"

rm -rf vllm

git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}

# Remove numba from requirements
if [ -f "requirements/cpu.txt" ]; then
  sed -i '/^numba/d' requirements/cpu.txt
fi

if [ -f "pyproject.toml" ]; then
  sed -i '/numba/d' pyproject.toml
fi

python3.12 -m pip install --no-build-isolation \
  --only-binary numpy,scipy,sentencepiece,msgspec,cbor2 \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  -r requirements/cpu.txt

python3.12 -m pip install llguidance xgrammar

export VLLM_TARGET_DEVICE=cpu
export MAX_JOBS=$(nproc)

export SETUPTOOLS_SCM_PRETEND_VERSION=${PACKAGE_VERSION#v}
python3.12 setup.py install
python3.12 setup.py bdist_wheel --dist-dir="${CURRENT_DIR}"

cd ${CURRENT_DIR}

echo "==================================================================="
echo "               vLLM WHEEL BUILT SUCCESSFULLY (v0.21.0)"
echo "==================================================================="

# -----------------------------------------------------------------------------
# Test - Run tests with installed vLLM
# -----------------------------------------------------------------------------

echo "-------------------- Testing installed vLLM ------------------------"

export VLLM_CPU_KVCACHE_SPACE=4

if ! python3.12 ${PACKAGE_DIR}/examples/basic/offline_inference/basic.py; then
  echo "INSTALL SUCCESS BUT TEST FAILED"
  exit 2
else
  echo "INSTALL AND TEST SUCCESS"
  exit 0
fi