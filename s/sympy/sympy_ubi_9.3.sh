#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : sympy
# Version          : 1.12.0
# Source repo      : https://github.com/sympy/sympy.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : SymPy Development Team
# Maintainer       : Rakshith R <rakshith.r5@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------- 

PACKAGE_NAME=sympy
PACKAGE_VERSION=${1:-sympy-1.12}
PACKAGE_URL=https://github.com/sympy/sympy.git

echo "------------------------------------------------------------Installing requirements for sympy------------------------------------------------------"
dnf update -y
dnf install -y python3-pip python3-devel gcc git 
pip install pytest

echo "------------------------------------------------------------Cloning sympy github repo--------------------------------------------------------------"
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "------------------------------------------------------------Installing sympy------------------------------------------------------"
if ! pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "------------------------------------------------------------Run tests for sympy------------------------------------------------------"
cd sympy/integrals/tests/
if ! pytest -p no:warnings --ignore=test_manual.py; then
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






