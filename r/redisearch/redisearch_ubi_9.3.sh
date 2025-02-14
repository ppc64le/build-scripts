#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : RediSearch
# Version          : v2.8.13
# Source repo      : https://github.com/RediSearch/RediSearch
# Tested on        : UBI:9.3
# Language         : C,Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=RediSearch
PACKAGE_VERSION=${1:-v2.8.13}
PACKAGE_URL=https://github.com/RediSearch/RediSearch

yum install -y https://dl.fedoraproject.org/pub/epel/9/Everything/ppc64le/Packages/e/epel-release-9-7.el9.noarch.rpm
yum install -y wget git gcc gcc-c++ make cmake libstdc++-static python3.11 python3.11-devel python3.11-pip gtest gtest-devel python3-psutil

git clone  --recursive $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd .install/
./install_boost.sh 1.83.0
cd ..

if ! make fetch ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 2
fi

if ! make build TEST=1 ; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make c-tests ; then
    echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
