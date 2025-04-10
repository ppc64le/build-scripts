#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pykrb5
# Version       : v0.5.1
# Source repo   : https://github.com/jborean93/pykrb5.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
PACKAGE_NAME=pykrb5
PACKAGE_VERSION=${1:-v0.5.1}
PACKAGE_URL=https://github.com/jborean93/pykrb5.git

# Install dependencies and tools
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip krb5-devel krb5-libs

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
pip install -r requirements-dev.txt

# Install the package
pip install .
pip install pytest wheel build Cython
pip install --upgrade cython
python -m build
# Install the package
if ! python3 -m setup build; then
echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi
