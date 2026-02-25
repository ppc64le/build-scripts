#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package       : vllm
# Version       : v0.15.1
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
PACKAGE_VERSION=${1:-v0.15.1}
PACKAGE_URL=https://github.com/vllm-project/vllm.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=vllm

TORCH_VERSION=v2.10.0
TORCHVISION_VERSION=v0.25.0
TORCH_URL=https://github.com/pytorch/pytorch.git
TORCHVISION_URL=https://github.com/pytorch/vision.git

echo "==================================================================="
echo "        vLLM FULL BUILD START (UBI 9.5 / POWER / v0.15.1)"
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
  llvm llvm-devel libevent-devel \
  clang clang-devel clang-libs \
  freetype-devel gmp-devel libjpeg-turbo-devel \
  cargo libcurl-devel \
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

# Ensure gcc-toolset runtime libraries are visible
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH}
export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LIBRARY_PATH}
export CMAKE_PREFIX_PATH=/opt/rh/gcc-toolset-13/root/usr:${CMAKE_PREFIX_PATH}

export CC=/opt/rh/gcc-toolset-13/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++

echo "CC  = $CC"
echo "CXX = $CXX"
gcc --version
g++ --version

# -----------------------------------------------------------------------------
# Python tooling
# -----------------------------------------------------------------------------
echo "-------------------- Upgrading Python tooling ---------------------"

python3.12 -m pip install --upgrade pip setuptools wheel

# -----------------------------------------------------------------------------
# Python binary wheels (POWER / devpi)
# -----------------------------------------------------------------------------
echo "-------------------- Installing Python dependencies ----------------"

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

python3.12 -m pip install \
  --prefer-binary \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  abseil-cpp==20240116.2 av==13.1.0 ffmpeg==7.1 lame==3.100 \
  libprotobuf==25.4 libvpx==1.13.1 llvmlite==0.44.0 \
  numba==0.62.0.dev0 openblas==0.3.29 opus==1.3.1 \
  protobuf==4.25.8 scipy==1.16.0 sentencepiece==0.2.0 \
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
pip install wheel "setuptools==69.5.1"
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
# Rust toolchain + hf_xet (HuggingFace Xet storage)
# -----------------------------------------------------------------------------
echo "-------------------- Installing Rust + hf_xet ----------------------"

if ! command -v rustup &> /dev/null; then
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source "$HOME/.cargo/env"
fi

rustup toolchain install 1.89.0
rustup default 1.89.0

# Environment for bindgen / outlines_core (RHEL/ppc64le)
export LIBCLANG_PATH=/usr/lib64
export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=/ -I/usr/include"

python3.12 -m pip install uv

git clone https://github.com/huggingface/xet-core.git
cd xet-core/hf_xet
uv build --wheel --out-dir dist
python3.12 -m pip install dist/*.whl
cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Build OpenCV headless from source (ppc64le)
# -----------------------------------------------------------------------------
echo "-------------------- Building OpenCV headless ----------------------"

OPENCV_VERSION=4.13.0

git clone https://github.com/opencv/opencv.git
cd opencv && git checkout 4.13.0

mkdir -p contrib_src && cd contrib_src
git clone https://github.com/opencv/opencv_contrib.git
cd opencv_contrib && git checkout 4.13.0
cd ${CURRENT_DIR}/opencv

# Patch vsx_utils.hpp for ppc64le (line 261)
HEADER_FILE="${CURRENT_DIR}/opencv/modules/core/include/opencv2/core/vsx_utils.hpp"
sed -i '261c\#if defined(__POWER10__) || (defined(__powerpc64__) && defined(__ARCH_PWR10__))' "$HEADER_FILE"
echo "vsx_utils.hpp line 261 now reads:"
sed -n '261p' "$HEADER_FILE"

PYTHON_INCLUDE=$(python3.12 -c "import sysconfig; print(sysconfig.get_path('include'))")
SITE_PACKAGES=$(python3.12 -c "import site; print(site.getsitepackages()[0])")

mkdir -p build && cd build

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TESTS=OFF \
  -DBUILD_PERF_TESTS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_opencv_apps=OFF \
  -DWITH_QT=OFF \
  -DWITH_GTK=OFF \
  -DWITH_OPENGL=OFF \
  -DWITH_V4L=OFF \
  -DWITH_FFMPEG=OFF \
  -DWITH_GSTREAMER=OFF \
  -DWITH_IPP=OFF \
  -DWITH_TBB=OFF \
  -DBUILD_opencv_python2=OFF \
  -DBUILD_opencv_python3=ON \
  -DPYTHON3_EXECUTABLE=$(which python3.12) \
  -DPYTHON3_INCLUDE_DIR=${PYTHON_INCLUDE} \
  -DPYTHON3_PACKAGES_PATH=${SITE_PACKAGES} \
  -DCMAKE_CXX_STANDARD=17 \
  -DCMAKE_CXX_STANDARD_REQUIRED=ON

make -j$(nproc)
make install
ldconfig

# Create dummy opencv-python-headless package so pip won't reinstall it
DUMMY_DIR="/tmp/opencv-python-headless-dummy"
mkdir -p $DUMMY_DIR && cd $DUMMY_DIR

cat > setup.py <<EOF
from setuptools import setup
setup(
    name="opencv-python-headless",
    version="$OPENCV_VERSION",
    description="Dummy package to satisfy pip for system-installed OpenCV",
    py_modules=[],
)
EOF

python3.12 -m pip wheel . --no-deps
python3.12 -m pip install opencv_python_headless-${OPENCV_VERSION}-py3-none-any.whl

cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Install grpcio from IBM devpi
# -----------------------------------------------------------------------------
echo "-------------------- Installing grpcio from IBM devpi ---------------"

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

python3.12 -m pip install grpcio==1.71.0 \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS}

# -----------------------------------------------------------------------------
# Build vLLM
# -----------------------------------------------------------------------------
echo "-------------------- Building vLLM ---------------------------------"

git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}

# Pin grpcio version in requirements to prevent pip from overwriting it
if [ -f "requirements/common.txt" ]; then
  sed -i 's/^grpcio.*/grpcio==1.71.0/' requirements/common.txt
fi

# Pin grpcio-tools in pyproject.toml to avoid pulling a conflicting grpcio version at build time
if [ -f "pyproject.toml" ]; then
  sed -i 's/"grpcio-tools"/"grpcio-tools==1.71.0"/' pyproject.toml
fi

python3.12 use_existing_torch.py

# sed -i 's/^torch/# torch/' requirements/cpu.txt
# sed -i 's/^torchvision/# torchvision/' requirements/cpu.txt
# sed -i 's/^torchaudio/# torchaudio/' requirements/cpu.txt
# sed -i 's/^outlines_core/# outlines_core/' requirements/common.txt
# sed -i 's/^scipy/# scipy/' requirements/common.txt

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
echo "               vLLM WHEEL BUILT SUCCESSFULLY (v0.15.1)"
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
