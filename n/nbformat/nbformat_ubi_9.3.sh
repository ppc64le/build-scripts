#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : nbformat
# Version          : v5.10.4
# Source repo      : https://github.com/jupyter/nbformat
# Tested on        : UBI 9.3
# Language         : Jupyter Notebook,Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=nbformat
PACKAGE_VERSION=${1:-v5.10.4}
PACKAGE_URL=https://github.com/jupyter/nbformat
PACKAGE_DIR=nbformat

yum install -y git python3 python3-devel python3-pip openssl-devel openssl gcc-toolset-13

# export paths
export PATH=$PATH:/usr/local/bin
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

#install dependency
pip install hatch pytest testpath packaging

# Clone package repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install
if !  pip install .; then
        echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
fi

# Test package
pip install nbformat[test]
if ! pytest ; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
        exit 0
fi
