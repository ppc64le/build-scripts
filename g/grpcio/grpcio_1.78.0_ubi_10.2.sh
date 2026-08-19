#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : grpcio
# Version       : 1.78.0
# Source repo   : https://github.com/grpc/grpc
# Tested on     : UBI:10.2
# Language      : C++, Python, C, Starlark, Shell
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : <First Last> <<email@ibm.com>>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

# Variables
PACKAGE_NAME=grpcio
PACKAGE_VERSION=${1:-1.78.0}
PACKAGE_URL=https://github.com/grpc/grpc
PACKAGE_DIR=grpc
CURRENT_DIR=$(pwd)

# Install system dependencies
# Python packages first (wrapper script requirement)
yum install -y python3.12 python3.12-devel python3.12-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    openssl openssl-devel make

# Configure GCC Toolset 15
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

# Install Python build tools
pip install --upgrade pip setuptools wheel build

# Clone repository
cd "$CURRENT_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"
git checkout v$PACKAGE_VERSION

# Initialise submodules (grpc requires them for third-party C deps)
git submodule sync --recursive
git submodule update --init --recursive

# Build grpcio using the system OpenSSL and Cython
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_WITH_CYTHON=1

# Install Python build-time requirements
pip install -r requirements.txt

# Install the package
if ! pip install --no-build-isolation . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Produce the wheel artifact and copy it to CURRENT_DIR
python3.12 setup.py bdist_wheel
cp dist/*.whl "$CURRENT_DIR/"

# Run tests
cd "$CURRENT_DIR"
if ! python3.12 -c "
import grpc
import grpc._cython
import grpc._cython._cygrpc
import grpc.beta
import grpc.framework
import grpc.framework.common
import grpc.framework.foundation
import grpc.framework.interfaces
import grpc.framework.interfaces.base
import grpc.framework.interfaces.face
print('All grpcio modules imported successfully')
" ; then
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
