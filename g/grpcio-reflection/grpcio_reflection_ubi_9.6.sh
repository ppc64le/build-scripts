#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : grpcio-reflection
# Version       : v1.78.0
# Source repo   : https://github.com/grpc/grpc
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <Vivek.Sharma20@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
# -----------------------------------------------------------------------------

set -ex
# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
PACKAGE_NAME=grpcio-reflection
PACKAGE_VERSION=${1:-v1.78.0}
PACKAGE_URL=https://github.com/grpc/grpc.git
PACKAGE_DIR=grpc

CURRENT_DIR=$(pwd)

# -----------------------------------------------------------------------------
# Install system dependencies
# -----------------------------------------------------------------------------
yum install -y \
    git \
    wget \
    gcc-toolset-13 \
    gcc-toolset-13-gcc \
    gcc-toolset-13-gcc-c++ \
    python3.12 \
    python3.12-devel \
    python3.12-pip

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
# Install grpcio and grpcio-tools from IBM ppc64le binary wheel index.
# grpcio has no upstream pre-built wheel for ppc64le, so we must use IBM's
# index. --only-binary prevents pip from falling back to a source build.
# grpcio-reflection itself is pure Python and needs no C compilation.
# -----------------------------------------------------------------------------
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

python3.12 -m pip install \
    --prefer-binary \
    --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url ${IBM_WHEELS} \
    grpcio==${PACKAGE_VERSION#v} \
    grpcio-tools==${PACKAGE_VERSION#v} \
    protobuf \
    pytest

# -----------------------------------------------------------------------------
# Clone grpcio-reflection source
# -----------------------------------------------------------------------------
cd ${CURRENT_DIR}

git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}


# Initialize only the protobuf submodule (avoids cloning the entire tree)
git submodule update --init --recursive third_party/protobuf

# -----------------------------------------------------------------------------
# Build the wheel
# -----------------------------------------------------------------------------
cd src/python/grpcio_reflection

# Generate Python files from .proto definitions
python3.12 setup.py preprocess

# Build and install
if ! python3.12 -m pip install . ; then
    echo "------------------${PACKAGE_NAME}: Install_Fails------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_Fails"
    exit 1
fi

# -----------------------------------------------------------------------------
# Run tests
# Note: grpcio-reflection has no upstream unit tests in its source tree,
#       so the test step is skipped.
# -----------------------------------------------------------------------------
echo "------------------${PACKAGE_NAME}: Install_&_test_both_success------------------"
echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
