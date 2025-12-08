#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : async_timeout
# Version          : v5.0.1
# Source repo      : https://github.com/aio-libs/async_timeout/
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=async_timeout
PACKAGE_VERSION=${1:-v5.0.1}
PACKAGE_URL=https://github.com/aio-libs/async_timeout/
PACKAGE_DIR=async_timeout

CURRENT_DIR=${PWD}

yum install -y git make cmake zip tar wget python3 python3-devel python3-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel 

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install pytest pytest-asyncio pytest-cov


#Build package
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Test package
if ! pytest tests ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
