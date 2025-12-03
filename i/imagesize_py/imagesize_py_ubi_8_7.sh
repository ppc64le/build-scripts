#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : imagesize_py
# Version       : 1.4.1
# Source repo   : https://github.com/shibukawa/imagesize_py
# Tested on     : UBI: 8.7
# Language      : python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e


# Variables
export PACKAGE_VERSION=${1:-"1.4.1"}
export PACKAGE_NAME=imagesize_py
export PACKAGE_URL=https://github.com/shibukawa/imagesize_py

# Install dependencies
yum install -y gcc gcc-c++ make cmake git wget  autoconf automake libtool pkgconf-pkg-config.ppc64le info.ppc64le python39-devel.ppc64le curl gzip tar bzip2 zip unzip zlib-devel yum-utils fontconfig.ppc64le fontconfig-devel.ppc64le openssl-devel python39-setuptools

pip3 install pytest
PATH=$PATH:/usr/local/bin/

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION



# Build package
if !(python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi


#Skipping "test_get_filelike" test as it check image size, and link of image provided in code does not exist. 

# Run test cases
if !(pytest -k "not test_get_filelike"); then
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

