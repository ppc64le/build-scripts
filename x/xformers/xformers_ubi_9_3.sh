#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : xformers
# Version       : 0.0.28
# Source repo   : https://github.com/facebookresearch/xformers.git
# Tested on     : UBI 9.3
# Language      : Python, C++
# Travis-Check  : True
# Script License: Apache License, Version 2.0
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=xformers
PACKAGE_VERSION=${1:-v0.0.28}
PACKAGE_URL=https://github.com/facebookresearch/xformers.git
PYTHON_VER=${2:-3.11}
PARALLEL=${PARALLEL:-$(nproc)}
export _GLIBCXX_USE_CXX11_ABI=1

# Install dependencies
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    git cmake ninja-build gcc gcc-c++ g++ rust cargo \
    python${PYTHON_VER}-devel python${PYTHON_VER}-pip jq

dnf install -y gcc-fortran pkg-config openblas-devel atlas

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# Install Python dependencies
python${PYTHON_VER} -m pip install ninja cmake 'pytest==8.2.2' hydra-core

# Install dependency - pytorch
PYTORCH_VERSION=${PYTORCH_VERSION:-$(curl -sSL https://api.github.com/repos/pytorch/pytorch/releases/latest | jq -r .tag_name)}

git clone https://github.com/pytorch/pytorch.git

cd pytorch

git checkout tags/$PYTORCH_VERSION

PPC64LE_PATCH="69cbf05"

if ! git log --pretty=format:"%H" | grep -q "$PPC64LE_PATCH"; then
    echo "Applying POWER patch."
    git config user.email "Puneet.Sharma21@ibm.com"
    git config user.name "puneetsharma21"
    git cherry-pick "$PPC64LE_PATCH"
else
    echo "POWER patch not needed."
fi

git submodule sync
git submodule update --init --recursive

# Set flags to suppress warnings
export CXXFLAGS="-Wno-unused-variable -Wno-unused-parameter"

pip${PYTHON_VER} install -r requirements.txt
MAX_JOBS=$PARALLEL python${PYTHON_VER} setup.py install

# Install dependency - Scipy
# install scipy dependency(numpy wheel gets built and installed) and build-setup dependencies
cd ..
git clone https://github.com/scipy/scipy
cd scipy
git checkout v1.14.1
git submodule update --init

python${PYTHON_VER} -m pip install meson ninja numpy 'setuptools<60.0' Cython
python${PYTHON_VER} -m pip install 'meson-python<0.15.0,>=0.12.1'
python${PYTHON_VER} -m pip install pybind11
python${PYTHON_VER} -m pip install 'patchelf>=0.11.0'
python${PYTHON_VER} -m pip install 'pythran<0.15.0,>=0.12.0'
python${PYTHON_VER} -m pip install build

python${PYTHON_VER}-m pip install --no-build-isolation .

# Build and install xformers
cd ..
if ! python${PYTHON_VER} -m pip install -e .; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success-------------------------"
fi

# Test installation
if python${PYTHON_VER} -c "import xformers"; then
    echo "------------------$PACKAGE_NAME::Install_Success---------------------"
else
    echo "------------------$PACKAGE_NAME::Install_Fail-------------------------"
    exit 2
fi

# Run Specific tests
export PY_IGNORE_IMPORTMISMATCH=1
if ! python${PYTHON_VER} -m pytest tests/test_unbind.py tests/test_rotary_embeddings.py tests/test_hydra_helper.py tests/test_compositional_attention.py tests/test_global_attention.py; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------"
    exit 2
else
    echo "------------------$PACKAGE_NAME:test_success-------------------------"
    exit 0
fi
