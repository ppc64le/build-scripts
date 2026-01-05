#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pillow
# Version       : 10.3.0
# Source repo   : https://github.com/python-pillow/Pillow
# Tested on     : UBI:8.10
# Language      : Python, C
# Ci-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Salil Verlekar <Salil.Verlekar2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pillow
PACKAGE_VERSION=${1:-10.3.0}
PACKAGE_URL=https://github.com/python-pillow/Pillow/

OS_NAME=`cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}'`

# install core dependencies
yum install -y python3.11 python3.11-pip python3.11-devel gcc git
python3.11 -m pip install 'setuptools>=67.8' build

# pillow minimum dependencies
yum install -y zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel

# clone source repository
git clone $PACKAGE_URL $PACKAGE_NAME

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# build wheel in /pillow/dist
if ! python3.11 -m build --wheel --no-isolation; then
        echo "------------------$PACKAGE_NAME:build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

# install and test the package
cd ..
python3.11 -m pip install pillow/dist/pillow-10.3.0-cp311-cp311-linux_ppc64le.whl
python3.11 -m pip show pillow

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi
