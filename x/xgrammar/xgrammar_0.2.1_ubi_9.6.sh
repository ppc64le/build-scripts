#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : xgrammar
# Version       : v0.2.1
# Source repo   : https://github.com/mlc-ai/xgrammar
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
# -----------------------------------------------------------------------------

#!/bin/bash
set -ex

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
PACKAGE_NAME=xgrammar
PACKAGE_VERSION=${1:-v0.2.1}
PACKAGE_URL=https://github.com/mlc-ai/xgrammar.git
PACKAGE_DIR=xgrammar

CURRENT_DIR=$(pwd)

# -----------------------------------------------------------------------------
# Install system dependencies
# -----------------------------------------------------------------------------
yum install -y git wget gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ make cmake ninja-build rust cargo openssl-devel libffi-devel python3.12 python3.12-devel python3.12-pip

# -----------------------------------------------------------------------------
# Enable GCC Toolset 13
# -----------------------------------------------------------------------------
source /opt/rh/gcc-toolset-13/enable

export CC=gcc
export CXX=g++

# -----------------------------------------------------------------------------
# Upgrade Python packaging tools
# -----------------------------------------------------------------------------
python3.12 -m pip install --upgrade \
    pip \
    setuptools \
    wheel

# -----------------------------------------------------------------------------
# Install Python build dependencies
# -----------------------------------------------------------------------------
python3.12 -m pip install \
    build \
    packaging \
    pytest \
    numpy \
    pydantic \
    typing_extensions \
    pybind11 \
    nanobind==2.5.0 \
    cmake \
    ninja \
    scikit-build-core \
    setuptools-rust

# -----------------------------------------------------------------------------
# Install Apache TVM-FFI v0.1.9 (required by xgrammar v0.2.1)
# -----------------------------------------------------------------------------
cd ${CURRENT_DIR}

git clone --recursive https://github.com/apache/tvm-ffi.git
cd tvm-ffi
git checkout v0.1.9

python3.12 -m pip install .

python3.12 -c "import tvm_ffi"

TVM_FFI_LIB=$(find / -name "libtvm_ffi.so" 2>/dev/null | head -1)

if [ -z "${TVM_FFI_LIB}" ]; then
    echo "ERROR: libtvm_ffi.so not found after tvm-ffi installation"
    exit 1
fi

export LD_LIBRARY_PATH=$(dirname "${TVM_FFI_LIB}"):${LD_LIBRARY_PATH}

echo "Found libtvm_ffi.so: ${TVM_FFI_LIB}"
echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"

cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Install Torch
# -----------------------------------------------------------------------------
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

python3.12 -m pip install \
    --prefer-binary \
    --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url ${IBM_WHEELS} \
    torch

# -----------------------------------------------------------------------------
# Install runtime dependencies
# -----------------------------------------------------------------------------
python3.12 -m pip install \
    transformers \
    tiktoken

# -----------------------------------------------------------------------------
# Clone xgrammar
# -----------------------------------------------------------------------------
git clone --recursive ${PACKAGE_URL}
cd ${PACKAGE_DIR}

git checkout ${PACKAGE_VERSION}
git submodule update --init --recursive

# -----------------------------------------------------------------------------
# Build native components
# -----------------------------------------------------------------------------
mkdir -p build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -Dnanobind_DIR=$(python3.12 -c "import nanobind; print(nanobind.cmake_dir())")

make -j"$(nproc)"

cd ..

# -----------------------------------------------------------------------------
# Clean scikit-build artifacts
# -----------------------------------------------------------------------------
export SKBUILD_BUILD_DIR=/tmp/${PACKAGE_NAME}_skbuild
rm -rf "${SKBUILD_BUILD_DIR}"

export CMAKE_GENERATOR=Ninja

# -----------------------------------------------------------------------------
# Install xgrammar
# -----------------------------------------------------------------------------
if ! python3.12 -m pip install --no-build-isolation .; then
    echo "------------------${PACKAGE_NAME}: Install_Fails------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_Fails"
    exit 1
fi

# -----------------------------------------------------------------------------
# Verify installation
# -----------------------------------------------------------------------------
python3.12 - <<EOF
import xgrammar
print("xgrammar imported successfully")
EOF

# -----------------------------------------------------------------------------
# Run tests
# -----------------------------------------------------------------------------
if ! pytest tests \
    -k "not test_reasoning_stag and not test_serialize_compiled_grammar"; then
    echo "------------------${PACKAGE_NAME}: Install_success_but_test_fails------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------${PACKAGE_NAME}: Install_&_test_both_success------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
