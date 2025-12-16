#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : flatbuffers
# Version       : v2.0.0
# Source repo   : https://github.com/google/flatbuffers.git
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=flatbuffers
PACKAGE_VERSION=${1:-v2.0.0}
PACKAGE_URL=https://github.com/google/flatbuffers.git
PACKAGE_DIR=flatbuffers/python
CURRENT_DIR="${PWD}"
export VERSION=$PACKAGE_VERSION

# Install dependencies and tools.
yum install -y wget gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran git make python3-devel python3-pip openssl-devel cmake
source /opt/rh/gcc-toolset-13/enable

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cmake ./
make
make install

#checkout to Python folder
cd python

# Ensure setuptools-compatible license handling by localizing LICENSE (if present) and rewriting invalid '../LICENSE' reference in setup.py for newer setuptools/Python versions
LICENSE_FILE=$(ls ../LICENSE ../LICENSE.txt ../license 2>/dev/null | head -n 1)

if [ -n "$LICENSE_FILE" ]; then
    [ ! -f LICENSE ] && cp "$LICENSE_FILE" LICENSE
fi
# Fix setup.py only if bad pattern exists
sed -i -E "s|license_files\s*=\s*'../LICENSE'\s*,?|license_files=['LICENSE'],|" setup.py

#install
if ! (pip3 install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
#skipping the testcases because some modules are not supported in all python verisons.

