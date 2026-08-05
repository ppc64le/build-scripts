#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : markupsafe
# Version       : 3.0.2
# Source repo   : https://github.com/pallets/markupsafe
# Tested on     : UBI:10.1
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh Sharma <shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=markupsafe
PACKAGE_VERSION=${1:-3.0.2}
PACKAGE_URL=https://github.com/pallets/markupsafe

yum install -y git gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran python3.12 python3.12-pip python3.12-devel gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel xz cmake zlib-devel openblas-devel

export PATH=/opt/rh/gcc-toolset-15/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH 

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Installing all the requirements
python3.12 -m pip install pytest setuptools

if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
