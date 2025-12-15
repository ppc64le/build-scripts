#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package       : jaraco.test
# Version       : v5.5.1
# Source repo   : https://github.com/jaraco/jaraco.test
# Tested on     : UBI 9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jaraco.test
PACKAGE_VERSION=${1:-v5.5.1}
PACKAGE_URL=https://github.com/jaraco/jaraco.test
PACKAGE_DIR=jaraco.test

yum install -y python3 python3-pip python3-devel ncurses git gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs make cmake python3-test
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
pip3 install setuptools wheel pytest 

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install the package
if ! python3 -m pip install -e .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! pytest; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "  
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_success_but_test_Fails"
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success"
fi
