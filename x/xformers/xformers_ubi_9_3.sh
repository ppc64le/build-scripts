#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : xformers
# Version       : v0.0.29
# Source repo   : https://github.com/facebookresearch/xformers.git
# Tested on     : UBI 9.3
# Language      : Python, C++
# Ci-Check  : True
# Script License: Apache License, Version 2.0
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=xformers
PACKAGE_VERSION=${1:-v0.0.29}
PACKAGE_URL=https://github.com/facebookresearch/xformers.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=xformers
PARALLEL=${PARALLEL:-$(nproc)}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
export _GLIBCXX_USE_CXX11_ABI=1
export BUILD_VERSION=${PACKAGE_VERSION#v}

# Install dependencies
yum install -y git gcc-toolset-13 ninja-build rust cargo python-devel python-pip jq pkg-config atlas

source /opt/rh/gcc-toolset-13/enable

curl -sL https://ftp2.osuosl.org/pub/ppc64el/openblas/latest/Openblas_0.3.29_ppc64le.tar.gz | tar xvf - -C /usr/local \
&& export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib

# Clone repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# Set version.txt to match the specified PACKAGE_VERSION
VERSION_NUM="${PACKAGE_VERSION#v}"  
echo "Fixing version.txt to $VERSION_NUM"
echo "$VERSION_NUM" > version.txt

# Install Python dependencies
pip3 install --upgrade pip setuptools wheel
pip3 install ninja 'cmake<4' 'pytest==8.2.2' hydra-core

# Install dependency - pytorch
PYTORCH_VERSION=v2.7.1
cd $CURRENT_DIR

git clone https://github.com/pytorch/pytorch.git

cd pytorch

git checkout tags/$PYTORCH_VERSION

PPC64LE_PATCH="69cbf05"

if ! git log --pretty=format:"%H" | grep -q "$PPC64LE_PATCH"; then
    echo "Applying POWER patch."
    git cherry-pick "$PPC64LE_PATCH" --no-commit
else
    echo "POWER patch not needed."
fi

git submodule sync
git submodule update --init --recursive

    # Set flags to suppress warnings
export CXXFLAGS="-Wno-unused-variable -Wno-unused-parameter"

pip3 install -r requirements.txt
MAX_JOBS=$PARALLEL python3 setup.py install

export LD_LIBRARY_PATH=$CURRENT_DIR/pytorch/build/lib/:$LD_LIBRARY_PATH
cd $CURRENT_DIR/$PACKAGE_NAME

# Build and install xformers
if ! pip3 install . --no-build-isolation -vvv; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Build_fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

# Run Specific tests
export PY_IGNORE_IMPORTMISMATCH=1

if ! pytest tests/ --ignore=tests/test_custom_ops.py --ignore=tests/test_sparsecs.py --ignore=tests/test_mem_eff_attention.py --ignore=tests/test_core_attention.py --ignore=tests/test_sparse_tensors.py --ignore=tests/test_checkpoint.py; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:both_install_and_test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
