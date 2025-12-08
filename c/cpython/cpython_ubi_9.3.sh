#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cpython
# Version          : v3.12.3
# Source repo      : https://github.com/python/cpython
# Tested on        : UBI: 9.3
# Language         : Python, C
# Ci-Check     : True
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

PACKAGE_NAME=cpython
PACKAGE_VERSION=${1:-v3.12.3}
PACKAGE_URL=https://github.com/python/cpython

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git gcc-c++ zlib zlib-devel

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

./configure
make

if ! make install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Install_Success"
    exit 0
fi


# Tests inside container fail as ipv6 and ftp is not enabled but tests are passing when tested in VM.

# if ! make test ; then
#     echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
#     exit 2
# else
#     echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
#     exit 0
# fi