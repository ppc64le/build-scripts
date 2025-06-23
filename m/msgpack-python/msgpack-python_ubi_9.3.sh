#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : msgpack-python
# Version        : v1.1.1
# Source repo    : https://github.com/msgpack/msgpack-python.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=msgpack-python
PACKAGE_DIR=msgpack-python
PACKAGE_VERSION=${1:-1.1.1}
PACKAGE_URL=https://github.com/msgpack/msgpack-python.git

# Install necessary system packages
yum install -y git python3 python3-devel python3-pip gcc make wget

# Upgrade pip and install build dependencies
pip3 install --upgrade pip setuptools wheel

# Clone the repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout v${PACKAGE_VERSION}

# Install build requirements
pip3 install -r requirements.txt
pip3 install cython build pytest

#Explicitly generating the C files with Cython:
cython msgpack/_cmsgpack.pyx

# Build and install the package
if ! python3 -m build --wheel; then
    echo "------------------$PACKAGE_NAME: Build_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Failure"
    exit 1
fi

# Install the built wheel
pip3 install dist/*.whl

# Run tests
if ! pytest; then
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
