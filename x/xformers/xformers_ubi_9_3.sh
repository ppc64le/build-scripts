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
BUILD_DEPS=${3:-true}
PARALLEL=${PARALLEL:-$(nproc)}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
export _GLIBCXX_USE_CXX11_ABI=1

# Install dependencies
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    git cmake ninja-build gcc gcc-c++ g++ rust cargo \
    python${PYTHON_VER}-devel python${PYTHON_VER}-pip jq

dnf install -y gcc-fortran pkg-config openblas-devel atlas

# Clone repository
if [ -z $PACKAGE_SOURCE_DIR ]; then
  git clone $PACKAGE_URL
  cd $PACKAGE_NAME  
else  
  cd $PACKAGE_SOURCE_DIR
fi

git checkout $PACKAGE_VERSION
git submodule update --init

# Install Python dependencies
python${PYTHON_VER} -m pip install ninja cmake 'pytest==8.2.2' hydra-core
python${PYTHON_VER} -m pip install --upgrade pip setuptools wheel


# Check BUILD_DEPS passed from Jenkins
echo "BUILD_DEPS: $BUILD_DEPS"

# Install PyTorch only if not installed and BUILD_DEPS is not False
if [ -z $BUILD_DEPS ] || [ "$BUILD_DEPS" == "true" ]; then

    # Install dependency - pytorch
    PYTORCH_VERSION=v2.5.1

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


    cd ..
else
    echo "Skipping PyTorch installation because BUILD_DEPS is set to False or not provided."
    python${PYTHON_VER} -m pip install -r requirements.txt
fi

# Build and install xformers
if ! python${PYTHON_VER} -m pip install -e . -vvv; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Build_fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

# Test installation
if python${PYTHON_VER} -c "import xformers"; then
    echo "------------------$PACKAGE_NAME::Install_Success---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success"
else
    echo "------------------$PACKAGE_NAME::Install_Fail-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Install_Fails"
    exit 2
fi

# Run Specific tests
export PY_IGNORE_IMPORTMISMATCH=1
if ! python${PYTHON_VER} -m pytest tests/test_unbind.py tests/test_rotary_embeddings.py tests/test_hydra_helper.py tests/test_compositional_attention.py tests/test_global_attention.py; then
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
