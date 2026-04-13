#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : xgrammar
# Version       : v0.1.33
# Source repo   : https://github.com/mlc-ai/xgrammar
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
# -----------------------------------------------------------------------------

set -e

# Variables
PACKAGE_NAME=xgrammar
PACKAGE_VERSION=${1:-v0.1.33}
PACKAGE_URL=https://github.com/mlc-ai/xgrammar
PACKAGE_DIR=xgrammar
CURRENT_DIR=$(pwd)

# -----------------------------------------------------------------------------
# Install system dependencies required for:
#  - building C++ bindings (gcc-toolset-13, make, cmake, ninja)
#  - building python extensions (python3.12-devel)
#  - building rust based dependencies (rust, cargo)
#  - SSL and libffi support (openssl-devel, libffi-devel)
# -----------------------------------------------------------------------------
echo "Installing dependencies..."
yum install -y git wget gcc-toolset-13 make cmake ninja-build \
    python3.12 python3.12-devel python3.12-pip \
    openssl-devel libffi-devel \
    rust cargo

# -----------------------------------------------------------------------------
# Upgrade pip, setuptools, and wheel to avoid build failures with modern
# pyproject.toml based projects.
# -----------------------------------------------------------------------------
python3.12 -m pip install --upgrade pip setuptools wheel

# -----------------------------------------------------------------------------
# Enable gcc-toolset-13.
# This ensures the newer GCC compiler is used instead of the system default GCC,
# which may not support newer C++ features required by xgrammar.
# -----------------------------------------------------------------------------
source /opt/rh/gcc-toolset-13/enable

# -----------------------------------------------------------------------------
# Install python build dependencies.
#
# Important:
# - xgrammar uses C++ bindings and requires nanobind/pybind style tooling.
# - setuptools-rust is required for building rust based python dependencies
#   like tiktoken (dependency pulled by xgrammar).
# - scikit-build-core is the backend used by xgrammar for building wheels.
# - ninja/cmake are installed via pip as well to ensure compatible versions.
# -----------------------------------------------------------------------------
echo "Installing Python build dependencies..."
python3.12 -m pip install pybind11 setuptools-rust build packaging pytest numpy nanobind build ninja cmake scikit-build-core

cd ${CURRENT_DIR}

# -----------------------------------------------------------------------------
# Clone the repository and checkout the required version.
# Also initialize submodules since xgrammar contains C++ components as submodules.
# -----------------------------------------------------------------------------
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# -----------------------------------------------------------------------------
# Build C++ artifacts manually using CMake.
# This step ensures all native libraries/bindings are generated properly.
# Explicitly passing Python3_EXECUTABLE ensures correct python version is used.
# -----------------------------------------------------------------------------
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DPython3_EXECUTABLE=/usr/bin/python3.12
make -j$(nproc)
cd ..

# -----------------------------------------------------------------------------
# xgrammar depends on torch. On ppc64le, torch wheels are usually not available
# from PyPI, so installed manually using a prebuilt wheel.
# -----------------------------------------------------------------------------
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
python3.12 -m pip install \
  --prefer-binary \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} torch==2.10.0

# -----------------------------------------------------------------------------
# scikit-build-core Build Directory Handling
#
# xgrammar uses scikit-build-core as its pyproject.toml backend.
# During pip install, scikit-build-core internally invokes CMake + Ninja.
#
# On repeated builds, stale files (like Makefile-based artifacts) can remain
# in the default build directory and cause Ninja to fail with:
#   "ninja: error: Makefile: expected '=', got ':'"
#
# To avoid such conflicts, we enforce a clean dedicated build directory.
# -----------------------------------------------------------------------------
export SKBUILD_BUILD_DIR=/tmp/${PACKAGE_NAME}_skbuild
rm -rf ${SKBUILD_BUILD_DIR}

# -----------------------------------------------------------------------------
# Force CMake generator to Ninja.
# This ensures scikit-build-core consistently uses Ninja instead of Makefiles.
# -----------------------------------------------------------------------------
export CMAKE_GENERATOR=Ninja

# -----------------------------------------------------------------------------
# Install xgrammar from source.
# --no-build-isolation ensures it uses the already installed build dependencies
# instead of creating a separate isolated environment (prevents missing backend
# errors like scikit_build_core.build not found).
# -----------------------------------------------------------------------------
if ! (python3.12 -m pip install --no-build-isolation .); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# -----------------------------------------------------------------------------
# Test Execution Notes:
# Some tests require HuggingFace gated models.
# If you do not have a HuggingFace token, run tests excluding those markers.
# -----------------------------------------------------------------------------
if ! pytest -m "not hf_token_required" ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
