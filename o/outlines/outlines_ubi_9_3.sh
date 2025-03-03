#!/bin/bash -e
# ------------------------------------------------------------------------
#
# Package       : outlines
# Version       : 0.1.11
# Source repo   : https://github.com/dottxt-ai/outlines.git
# Tested on     : UBI 9.3
# Language      : Python, C++
# Travis-Check  : True
# Script License: Apache License, Version 2.0
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned repository.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ------------------------------------------------------------------------

PACKAGE_NAME=outlines
PACKAGE_VERSION=${1:-0.1.11}
PACKAGE_URL=https://github.com/dottxt-ai/outlines.git
PYTHON_VER=${PYTHON_VERSION:-3.11}
BUILD_DEPS=${BUILD_DEPS:-true}
PARALLEL=${PARALLEL:-$(nproc)}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
export _GLIBCXX_USE_CXX11_ABI=1

# Install dependencies
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    git cmake ninja-build gcc-toolset-13 cargo \
    python${PYTHON_VER}-devel python${PYTHON_VER}-pip jq openssl openssl-devel \
    pkg-config atlas

source /opt/rh/gcc-toolset-13/enable

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

curl -sL https://ftp2.osuosl.org/pub/ppc64el/openblas/latest/Openblas_0.3.29_ppc64le.tar.gz | tar xvf - -C /usr/local \
&& export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib

export OPENSSL_DIR=/usr
export OPENSSL_LIB_DIR=/usr/lib64
export OPENSSL_INCLUDE_DIR=/usr/include

# Clone repository
if [ -z $PACKAGE_SOURCE_DIR ]; then
  git clone $PACKAGE_URL
  cd $PACKAGE_NAME  
else  
  cd $PACKAGE_SOURCE_DIR
fi

git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# Install Python dependencies
python${PYTHON_VER} -m pip install --upgrade pip ninja cmake 'pytest==8.2.2' hydra-core setuptools wheel

# Check BUILD_DEPS passed
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
        git config user.email "Your.Email@example.com"
        git config user.name "YourName"
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
    python${PYTHON_VER} -m pip install torch
fi

# Build and install outlines
if ! python${PYTHON_VER} -m pip install -e .; then
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
if python${PYTHON_VER} -c "import outlines"; then
    echo "------------------$PACKAGE_NAME:Install_Success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success"
else
    echo "------------------$PACKAGE_NAME:Install_Fail---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Install_Fails"
    exit 2
fi


# Run Specific tests
python${PYTHON_VER} -m pip install openai

if ! python${PYTHON_VER} -m pytest tests/models/test_openai.py; then
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

