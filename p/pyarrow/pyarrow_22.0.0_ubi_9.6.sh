#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyarrow
# Version       : apache-arrow-22.0.0
# Source repo   : https://github.com/apache/arrow
# Tested on     : UBI:9.6
# Language      : Python, C
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : puneetsharma21 <puneet.sharma21@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

WORKDIR=$(pwd)
PACKAGE_NAME=pyarrow
PACKAGE_VERSION=${1:-apache-arrow-22.0.0}
PACKAGE_URL=https://github.com/apache/arrow
PYTHON_VERSION=3.11

echo "Install dependencies and tools."
dnf install -y gcc-toolset-13 make cmake ninja-build libomp-devel \
               git python${PYTHON_VERSION} python${PYTHON_VERSION}-devel python${PYTHON_VERSION}-pip \
               openssl openssl-devel zlib-devel libuuid-devel libcurl-devel libatomic

# Enable GCC toolset
source /opt/rh/gcc-toolset-13/enable
export CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++

# GCC toolset 13 does not include libatomic, causing '-latomic not found' during linking.
# Symlink the system-provided libatomic.so.1 so the compiler can resolve it.
ln -s /usr/lib64/libatomic.so.1   /opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13/libatomic.so

# Installing Python build dependencies
python${PYTHON_VERSION} -m pip install build wheel setuptools numpy setuptools_scm Cython

echo "Entering Pyarrow source directory..."
git clone $PACKAGE_URL
cd arrow
git checkout $PACKAGE_VERSION
git submodule update --init --recursive
echo "Repository cloned and checked out to version $PACKAGE_VERSION."

cd cpp
mkdir -p release && cd release
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DARROW_PYTHON=ON \
      -DARROW_PARQUET=ON \
      -DARROW_ORC=ON \
      -DARROW_FILESYSTEM=ON \
      -DARROW_FLIGHT=ON \
      -DARROW_WITH_LZ4=ON \
      -DARROW_WITH_ZSTD=ON \
      -DARROW_WITH_SNAPPY=ON \
      -DARROW_JSON=ON \
      -DARROW_CSV=ON \
      -DARROW_DATASET=ON \
      -DARROW_S3=ON \
      -DARROW_BUILD_TESTS=OFF \
      -DARROW_SUBSTRAIT=ON \
      -DProtobuf_SOURCE=BUNDLED \
      -DARROW_DEPENDENCY_SOURCE=BUNDLED \
    ..
make -j$(nproc)
make install
cd ../../python
export BUILD_TYPE=release

echo "Building pyarrow wheel..."
if ! python${PYTHON_VERSION} setup.py build_ext --build-type=$BUILD_TYPE --bundle-arrow-cpp bdist_wheel ; then
    echo "------------------$PACKAGE_NAME:wheel_built_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Wheel_Built_Fails"
    exit 1
fi

echo "Installing pyarrow wheel..."
if ! python${PYTHON_VERSION} -m pip install dist/*.whl; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd "$WORKDIR"

echo "Validating pyarrow installation..."

if ! python${PYTHON_VERSION} <<'EOF'
import pyarrow
print("pyarrow version:", pyarrow.__version__)

import pyarrow.lib as _lib
print("pyarrow.lib loaded:", _lib.__name__)

import pyarrow.parquet as parquet
print("pyarrow.parquet loaded:", parquet.__name__)

import pyarrow.dataset as dataset
print("pyarrow.dataset loaded:", dataset.__name__)

import pyarrow.flight as flight
print("pyarrow.flight loaded:", flight.__name__)

import pyarrow.substrait as substrait
print("pyarrow.substrait loaded:", substrait.__name__)
EOF
then
    echo "------------------ pyarrow: validation_failed ------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Validation_Failed"
    exit 1
fi

echo "PyArrow validation successful"





