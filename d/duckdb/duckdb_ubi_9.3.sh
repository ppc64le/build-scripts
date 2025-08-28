#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : duckdb
# Version       : v1.1.3
# Source repo   : https://github.com/duckdb/duckdb.git
# Tested on     : UBI:9.3
# Language      : Python, C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=duckdb
PACKAGE_VERSION=${1:-v1.1.3}
PACKAGE_URL=https://github.com/duckdb/duckdb.git

# Install necessary system packages
dnf install -y make cmake ninja-build libomp-devel git clang python3 python3-pip python3-devel

# Set up GCC toolset
export PATH=/opt/rh/gcc-toolset-14/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-14/root/usr/lib64:$LD_LIBRARY_PATH
export CC=/opt/rh/gcc-toolset-14/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-14/root/usr/bin/g++

# Reduce memory usage by limiting parallel jobs
export MAKEFLAGS="-j2"
export CMAKE_BUILD_PARALLEL_LEVEL=2

# Upgrade pip & setuptools
python3 -m pip install --upgrade pip setuptools wheel

# Install build dependencies
python3 -m pip install build pybind11

# Clone the repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

cd tools/pythonpkg

# Set environment variables to reduce memory usage
export CFLAGS="-O1 -pipe"
export CXXFLAGS="-O1 -pipe"

# Build Package 
if ! python3 -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME: Build_Fail------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fail"
    exit 1
fi

cd /tmp

# Run tests
if ! python3 -c "import duckdb; print(duckdb.__version__)"; then
    echo "------------------$PACKAGE_NAME: Tests_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Fail"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Install & test both success ---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
