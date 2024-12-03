#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : mpld3
# Version       : 0.5.10
# Source repo : https://github.com/mpld3/mpld3
# Tested on     : CentOS
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# Note: No test cases are available for this package.
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e
# Variables
PACKAGE_NAME=mpld3
PACKAGE_VERSION=${1:-v0.5.10}
PACKAGE_URL=https://github.com/mpld3/mpld3

# Step 1: Install dependencies
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openblas-devel cmake libjpeg-devel zlib-devel freetype-devel  libwebp-devel make python3-setuptools
pip3 install numpy matplotlib pillow wheel build diffimg
pip3 install setuptools==65.5.0

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Step 2: Fix the deprecation warning in setup.py (description-file)
echo "Fixing deprecation warning in setup.py..."
sed -i 's/description-file/description_file/' setup.py

#install
if ! (python3 -m setup install); then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
        exit 2
else
     echo "------------------$PACKAGE_NAME::Install_Success---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Install_Success"
fi

#run tests
if !(pytest -m "not supported or test_verify_cert_signature or verify_cert_signature" --ignore=mpld3/tests/test_d3_snapshots.py --disable-warnings); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Build_and_Test_Success"
fi
