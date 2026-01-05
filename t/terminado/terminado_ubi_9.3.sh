#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : terminado
# Version       : v0.18.1
# Source repo   : https://github.com/takluyver/terminado.git
# Tested on     : UBI: 9.5
# Language      : python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
#
# Disclaimer   : This script has been tested in root mode on given
# ==========   platform using the mentioned version of the package.
#              It may not work as expected with newer versions of the
#              package and/or distribution. In such case, please
#              contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

# Variables
PACKAGE_VERSION=${1:-"v0.18.1"}
PACKAGE_NAME=terminado
PACKAGE_URL=https://github.com/takluyver/terminado.git
PACKAGE_DIR=terminado
# Install dependencies
yum install -y python3-devel python3-pip git gcc-toolset-13 
source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

pip install pytest 
pip install pytest-timeout

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build package
if ! (python3 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if ! pytest -p no:warnings; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
