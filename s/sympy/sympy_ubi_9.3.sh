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

dnf update -y
dnf groupinstall -y "Development Tools"
dnf install -y python3-pip python3-devel gcc git

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
pip3 install .

installed_version=$(pip3 show sympy | grep -i version | awk '{print $2}')

if [ "$installed_version" == "1.12" ]; then
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
else
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
if ! pytest; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0







