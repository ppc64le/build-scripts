#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : onnxruntime
# Version       : v1.9.0, v1.10.0
# Source repo   : https://github.com/microsoft/onnxruntime.git
# Tested on     : UBI 8.5
# Language      : C++
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhimrao Patil {Bhimrao.Patil@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=onnxruntime
PACKAGE_VERSION=1.9.0
PACKAGE_URL=https://github.com/microsoft/onnxruntime.git

yum install -y python3 git cmake gcc-c++ java-1.8.0-openjdk-devel
cd /home
if [ -d "$PACKAGE_NAME" ] ; then
        rm -rf $PACKAGE_NAME
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 0
fi	

#git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout v$PACKAGE_VERSION
./build.sh

exit 0

