#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : greenlet
# Version          : 4.1.5
# Source repo      : https://github.com/brandon-rhodes/pyephem.git
# Tested on        : UBI 8.7
# Language         : C, Python
# Travis-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pyephem
PACKAGE_VERSION=${1:-4.1.5}
PACKAGE_URL=https://github.com/brandon-rhodes/pyephem.git

wrkdir=`pwd`

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y python38-devel.ppc64le git gcc gcc-c++


git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! python3 setup.py build_ext -i ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python3 -m unittest discover ephem ; then
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