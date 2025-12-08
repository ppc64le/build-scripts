#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : sphinx-gallery
# Version          : v0.19.0
# Source repo      : https://github.com/sphinx-gallery/sphinx-gallery
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

PACKAGE_NAME=sphinx-gallery
PACKAGE_VERSION=${1:-v0.19.0}
PACKAGE_URL=https://github.com/sphinx-gallery/sphinx-gallery
PACKAGE_DIR=sphinx-gallery

CURRENT_DIR=${PWD}

yum install -y git make cmake zip tar wget python3 python3-devel python3-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel libxml2-devel libxslt-devel

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install --upgrade pip
pip install pytest pytest-cov lxml

#Build package
if ! pip install --ignore-installed . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Test package
if ! pytest sphinx_gallery ; then
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
