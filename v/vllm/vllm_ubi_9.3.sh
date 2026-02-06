#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : vllm
# Version       : v0.8.4
# Source repo   : https://github.com/vllm-project/vllm
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  :     True
# Script License: Apache License 2.0
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
# Variables
PACKAGE_NAME=vllm
PACKAGE_VERSION=${1:-v0.8.4}
PACKAGE_URL=https://github.com/vllm-project/vllm.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=vllm

TORCH_VERSION=v2.8.0
TORCHVISION_VERSION=v0.23.0
TORCH_URL=https://github.com/pytorch/pytorch.git
TORCHVISION_URL=https://github.com/pytorch/vision.git

export PYTHON=/usr/bin/python3.12
# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------
yum install -y yum-utils

yum install -y \
  git wget tar gzip xz which procps-ng yum-utils \
  --allowerasing

yum install -y \
  git make cmake gcc-toolset-13 \
  python3.12 python3.12-devel python3.12-pip m4 \
  unzip zip wget patch \
  openssl-devel sqlite-devel \
  llvm-devel libevent-devel openblas-devel \
  freetype-devel gmp-devel libjpeg-turbo-devel \
  cargo libcurl-devel  \
  which procps-ng yum-utils \
  gcc-toolset-13-libatomic-devel \
  --allowerasing

# -----------------------------------------------------------------------------
# Enable GCC toolset (CRITICAL: must stay enabled for entire script)
# -----------------------------------------------------------------------------
echo "-------------------- Enabling GCC toolset --------------------------"

source /opt/rh/gcc-toolset-13/enable

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

python3.12 -m pip install --upgrade pip setuptools wheel cython

# -----------------------------------------------------------------------------
# Python binary wheels (POWER / devpi)
#-----------------------------------------------------------------------------
# echo "-------------------- Installing Python dependencies ----------------"
echo "-----------flex installing------------------"
wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4
echo "Configuring flex installation..."
./configure --prefix=/usr/local
echo "Compiling the source code for flex..."
make -j$(nproc)
echo "Installing flex..."
make install
cd $CURRENT_DIR 
echo "-----------flex installed------------------"

echo "-------bison installing----------------------"
wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
tar -xvf bison-3.8.2.tar.gz
cd bison-3.8.2
echo "Configuring bison installation..."
./configure --prefix=/usr/local
echo "Compiling the source code bison..."
make -j$(nproc)
echo "Installing bison..."
make install
cd $CURRENT_DIR

echo "-----------------numactl installing-----------------------"
yum install -y git autoconf automake libtool
# Clone the repository
git clone https://github.com/numactl/numactl numactl
cd numactl
git checkout v2.0.19
./autogen.sh
./configure
make
make install

cd $CURRENT_DIR


echo "-----------------boost_cpp installing-----------------------"

git clone https://github.com/boostorg/boost
cd boost
git checkout boost-1.81.0
git submodule update --init

mkdir Boost_prefix
export BOOST_PREFIX=$(pwd)/Boost_prefix

INCLUDE_PATH="${BOOST_PREFIX}/include"
LIBRARY_PATH="${BOOST_PREFIX}/lib"

export target_platform=$(uname)-$(uname -m)
CXXFLAGS="${CXXFLAGS} -fPIC"
TOOLSET=gcc

 # http://www.boost.org/build/doc/html/bbv2/tasks/crosscompile.html
cat <<EOF > tools/build/example/site-config.jam
using ${TOOLSET} : : ${CXX} ;
EOF

LINKFLAGS="${LINKFLAGS} -L${LIBRARY_PATH}"

CXXFLAGS="$(echo ${CXXFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' |sed 's/ -mtune=[^ ]*//g')" \
CFLAGS="$(echo ${CFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' |sed 's/ -mtune=[^ ]*//g')" \
    CXX=${CXX_FOR_BUILD:-${CXX}} CC=${CC_FOR_BUILD:-${CC}} ./bootstrap.sh \
    --prefix="${BOOST_PREFIX}" \
    --without-libraries=python \
    --with-toolset=${TOOLSET} \
    --with-icu="${BOOST_PREFIX}" || (cat bootstrap.log; exit 1)
	 ADDRESS_MODEL=64
    ARCHITECTURE=power
	ABI="sysv"
	 BINARY_FORMAT="elf"

	 export CPU_COUNT=$(nproc)

echo " Building and installing Boost...."
./b2 -q \
    variant=release \
    address-model="${ADDRESS_MODEL}" \
    architecture="${ARCHITECTURE}" \
    binary-format="${BINARY_FORMAT}" \
    abi="${ABI}" \
    debug-symbols=off \
    threading=multi \
    runtime-link=shared \
    link=shared \
    toolset=${TOOLSET} \
    include="${INCLUDE_PATH}" \
    cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
    linkflags="${LINKFLAGS}" \
    --layout=system \
    -j"${CPU_COUNT}" \
    install

# Remove Python headers as we don't build Boost.Python.
rm "${BOOST_PREFIX}/include/boost/python.hpp"
rm -r "${BOOST_PREFIX}/include/boost/python"
cd $CURRENT_DIR




python3.12 -m pip install \
  --trusted-host wheels.developerfirst.ibm.com \
  "abseil-cpp @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/419/275773a4cc480/abseil_cpp-20240116.2-py3-none-any.whl" \
  "av @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/b09/d74303b7aaf7f/av-13.1.0-cp312-cp312-linux_ppc64le.whl" \
  "ffmpeg @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/25d/9b7b985a577b9/ffmpeg-7.1-py3-none-any.whl" \
  "lame @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/923/40f226ef59d45/lame-3.100-py3-none-any.whl" \
  "libprotobuf @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/e53/57a336598c208/libprotobuf-25.4-py3-none-manylinux2014_ppc64le.whl" \
  "libvpx @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/328/cfde06a744e3d/libvpx-1.13.1-py3-none-any.whl" \
  "llvmlite @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/ddd/ebf05d58bd563/llvmlite-0.44.0-cp312-cp312-linux_ppc64le.whl" \
  "numba @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/609/d7a83e5ac7944/numba-0.62.0.dev0-cp312-cp312-linux_ppc64le.whl" \
  "openblas @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/523/31f6718639cba/openblas-0.3.29-py3-none-manylinux2014_ppc64le.whl" \
  "opus @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/bec/40c21ed2fe31b/opus-1.3.1-py3-none-any.whl" \
  "protobuf @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/5e5/a6c4d93fcc5cd/protobuf-4.25.8-cp312-cp312-linux_ppc64le.whl" \
  "scipy @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/4e1/4b512f33efb85/scipy-1.16.0-cp312-cp312-linux_ppc64le.whl" \
  "sentencepiece @ https://wheels.developerfirst.ibm.com/ppc64le/linux/+f/161/51fddd15aec51/sentencepiece-0.2.0-cp312-cp312-linux_ppc64le.whl" \
  certifi charset-normalizer filelock fsspec idna \
  Jinja2 MarkupSafe mpmath networkx requests \
  sympy tqdm typing_extensions urllib3 numpy


python3.12 -m pip install cmake pyyaml packaging openpyxl setuptools_scm

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
git submodule sync
git submodule update --init --recursive

python3.12 -m pip install -r requirements.txt
python3.12 setup.py build_ext -j$(nproc)
python3.12 setup.py install

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
# Build vLLM
# -----------------------------------------------------------------------------
echo "-------------------- Building vLLM ---------------------------------"

git clone -b ${PACKAGE_VERSION} ${PACKAGE_URL}
cd ${PACKAGE_DIR}

# Keep your existing filters
sed -i 's/^torch/# torch/' requirements/cpu.txt
sed -i 's/^torchvision/# torchvision/' requirements/cpu.txt
sed -i 's/^torchaudio/# torchaudio/' requirements/cpu.txt
sed -i 's/^outlines_core/# outlines_core/' requirements/common.txt
sed -i 's/^scipy/# scipy/' requirements/common.txt

# NEW: scrub deprecated extras if present anywhere
sed -i 's/huggingface-hub\[hf_xet\]/huggingface-hub/g' requirements/*.txt || true
sed -i -e 's/.*torch.*//g' pyproject.toml requirements/*.txt

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

python3.12 -m pip install "huggingface-hub>=0.32.0" "transformers<=4.57.3"
export VLLM_TARGET_DEVICE=cpu
export MAX_JOBS=$(nproc)

# AVOID eggs: build and install via pip/wheel instead of setup.py install
export SETUPTOOLS_SCM_PRETEND_VERSION=0.8.4
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
