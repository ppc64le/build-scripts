#!/bin/bash -e 
# -----------------------------------------------------------------------------
#
# Package          : jdcal
# Version          : master	
# Source repo      : https://github.com/phn/jdcal
# Tested on	       : UBI 8.7
# Language         : Python
# Travis-Check     : True
# Script License   : BSD-2-Clause license
# Maintainer       : vinodk99 <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=jdcal
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/phn/jdcal

yum install -y python3 git

git clone $PACKAGE_URL 
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
python3 -m pip install pytest

if ! python3 -m pip install .; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest ; then
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
