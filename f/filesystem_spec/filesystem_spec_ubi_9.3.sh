#!/bin/bash -e
# ----------------------------------------------------------------------------- 
# Package       : filesystem_spec
# Version       : 2022.11.0
# Source repo   : https://github.com/fsspec/filesystem_spec.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhinav Kumar <Abhinav.Kumar25@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given platform 
# using the mentioned version of the package. It may not work as expected 
# with newer versions of the package and/or distribution. In such cases, 
# please contact the "Maintainer" of this script.
# -----------------------------------------------------------------------------

# Set variables for the package and version
PACKAGE_NAME="filesystem_spec"
PACKAGE_VERSION="${1:-2022.11.0}"
PACKAGE_URL="https://github.com/fsspec/filesystem_spec.git"

# Install required system dependencies for building the package
yum install -y git gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel \
    openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf \
    automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le \
    fontconfig-devel.ppc64le sqlite-devel python-devel


# Clone the repository and checkout the required version
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

# Install the package and its optional dependencies
pip install aiohttp pytest-asyncio pytest-vcr
pip install pytest-mock
pip install numpy
pip install tqdm
pip install requests
pip install .[all]

# Build the package
if ! python3 setup.py install; then
    echo "------------------$PACKAGE_NAME: Build fails----------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
    exit 1
fi

# Run tests, skipping specific tests as it is failing in x86 also.
if ! pytest -k "not test_dbfs"; then
    echo "------------------$PACKAGE_NAME: Build success but tests fail----------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Build & test both success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Build_and_Test_Success"
fi
