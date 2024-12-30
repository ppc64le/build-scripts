#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: libclang
# Version	: llvm-14.0.6
# Source repo	: https://github.com/sighingnow/libclang
# Tested on	: UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Pranith Rao <Pranith.Rao@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=libclang
PACKAGE_VERSION=${1:-'llvm-14.0.6'}
PACKAGE_URL=https://github.com/sighingnow/libclang

yum install -y git python3 python3-devel.ppc64le
PATH=$PATH:/usr/local/bin/

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if [ -f "setup.py" ];then
        if ! python3 setup.py install ; then
        echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
        exit 1
        fi
        echo "------------------$PACKAGE_NAME:Install_successfull-------------------------------------"
else
        echo "setup.py not present"
fi