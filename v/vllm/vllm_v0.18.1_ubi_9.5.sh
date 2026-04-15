#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package       : vllm
# Version       : v0.18.1
# Source repo   : https://github.com/vllm-project/vllm
# Tested on     : UBI:9.5
# Language      : Python
# Ci-Check      : True
# Script License: Apache License 2.0
# Maintainer    : Akash Kaothalkar <akash.kaothalkar@ibm.com>
#
# -----------------------------------------------------------------------------

set -eo pipefail

PACKAGE_NAME=vllm
PACKAGE_VERSION=${1:-v0.18.1}
PACKAGE_URL=https://github.com/vllm-project/vllm.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=vllm

echo "==================================================================="
echo "        vLLM FULL BUILD START (UBI 9.5 / POWER / v0.18.1)"
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
  unzip zip wget patch \
  openssl-devel sqlite-devel \
  freetype-devel gmp-devel libjpeg-turbo-devel \
  cargo libcurl-devel \
  autoconf automake libtool pkgconfig \
  openblas-devel \
  glibc-headers kernel-headers glibc-devel libstdc++-devel \
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

# Ensure headers and libs are visible to subsequent builds
export CPLUS_INCLUDE_PATH=/usr/local/include:${CPLUS_INCLUDE_PATH}
export LIBRARY_PATH=/usr/local/lib:${LIBRARY_PATH}
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
export CMAKE_PREFIX_PATH=/usr/local:${CMAKE_PREFIX_PATH}

cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Build Protobuf from source
# -----------------------------------------------------------------------------

echo "-------------------- Building Protobuf 3.20.3 from source -----------"

wget https://github.com/protocolbuffers/protobuf/releases/download/v3.20.3/protobuf-cpp-3.20.3.tar.gz
tar --no-same-owner -xvf protobuf-cpp-3.20.3.tar.gz
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

python3.12 -m pip install --upgrade pip setuptools uv
python3.12 -m uv pip install --system --index-strategy unsafe-best-match wheel \
"setuptools==69.5.1" \
ninja \
setuptools_scm \
packaging \
cmake \
cython

# -----------------------------------------------------------------------------
# Python dependencies
# -----------------------------------------------------------------------------

echo "-------------------- Installing Python dependencies ----------------"

# Increase uv network timeout to 10 minutes to prevent CI drops on multi-GB wheels
export UV_HTTP_TIMEOUT=600
export UV_NATIVE_TLS=1

echo "grpcio==1.71.0" > /tmp/constraints.txt
echo "grpcio-tools==1.71.0" >> /tmp/constraints.txt
echo "scipy==1.16.0" >> /tmp/constraints.txt
echo "sentencepiece==0.2.0" >> /tmp/constraints.txt

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

python3.12 -m uv pip install --system --index-strategy unsafe-best-match -c /tmp/constraints.txt \
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

if [ -f "requirements/common.txt" ]; then
  sed -i 's/^grpcio[ >=~].*/grpcio==1.71.0/' requirements/common.txt
  sed -i 's/^grpcio$/grpcio==1.71.0/' requirements/common.txt
fi

if [ -f "pyproject.toml" ]; then
  sed -i 's/"grpcio-tools.*"/"grpcio-tools==1.71.0"/' pyproject.toml
  sed -i 's/"grpcio[ >=~].*"/"grpcio==1.71.0"/' pyproject.toml
fi

# Constraints already created upstream

if [ -f "requirements/cpu.txt" ]; then
  sed -i '/^torchvision/d' requirements/cpu.txt
fi

# TCMalloc is currently unsupported on PowerPC. Conditionally preload libgomp instead for ppc64le.
if [ -f "$CURRENT_DIR/$PACKAGE_NAME/vllm/v1/worker/cpu_worker.py" ]; then
  sed -i '/import sys/a import platform' vllm/v1/worker/cpu_worker.py
  sed -i -e '/if sys.platform.startswith("linux"):/a\
            if platform.machine() == "ppc64le":\
                check_preloaded_libs("libgomp")\
            else:' -e 's/check_preloaded_libs("libtcmalloc")/    check_preloaded_libs("libtcmalloc")/' -e '/if current_platform.get_cpu_architecture() == CpuArchEnum.X86:/s/^/    /' -e '/check_preloaded_libs("libiomp")/s/^/    /' vllm/v1/worker/cpu_worker.py
fi

python3.12 -m uv pip install --system --index-strategy unsafe-best-match -c /tmp/constraints.txt \
  --only-binary numpy,scipy,sentencepiece \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  -r requirements/cpu.txt

python3.12 -m uv pip install --system --index-strategy unsafe-best-match llguidance xgrammar

export VLLM_TARGET_DEVICE=cpu
export MAX_JOBS=$(nproc)

python3.12 setup.py install
python3.12 setup.py bdist_wheel --dist-dir="${CURRENT_DIR}"

cd ${CURRENT_DIR}

echo "==================================================================="
echo "               vLLM WHEEL BUILT SUCCESSFULLY (v0.18.0)"
echo "==================================================================="

# -----------------------------------------------------------------------------
# Build TorchVision
# -----------------------------------------------------------------------------
echo "-------------------- Building TorchVision v0.25.1 ------------------"

for i in {1..5}; do
  git clone https://github.com/pytorch/vision.git && break || { echo "git clone failed, retrying in 15 seconds..."; sleep 15; }
done
cd vision
git checkout v0.25.0
python3.12 -m uv pip install --system --index-strategy unsafe-best-match wheel "setuptools==69.5.1"
USE_FFMPEG=1 USE_JPEG=1 USE_PNG=1 python3.12 setup.py install

cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Test
# -----------------------------------------------------------------------------

echo "Running basic offline inference example..."

export VLLM_CPU_KVCACHE_SPACE=4
export LD_PRELOAD=$(find /opt/rh/gcc-toolset-13/root/usr/lib64/ -name "libgomp.so*" | head -n 1)

if ! python3.12 ${PACKAGE_DIR}/examples/basic/offline_inference/basic.py; then
  echo "INSTALL SUCCESS BUT TEST FAILED"
  exit 2
else
  echo "INSTALL AND TEST SUCCESS"
  exit 0
fi
