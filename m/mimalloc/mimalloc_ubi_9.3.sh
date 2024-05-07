#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package           : mimalloc
# Version           : v2.1.4
# Source repo       : https://github.com/microsoft/mimalloc.git
# Tested on         : UBI:9.3
# Language          : C
# Travis-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Vinod K  <Vinod.K1@ibm.com >
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=mimalloc
PACKAGE_VERSION=${1:-v2.1.4}
PACKAGE_URL=https://github.com/microsoft/mimalloc.git
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

dnf update -y && dnf install -y git gcc gcc-c++ make cmake

git clone $PACKAGE_URL
git checkout $PACKAGE_VERSION
cd $PACKAGE_NAME

mkdir -p out/release
cd out/release
cmake ../..

if ! make -j $(nproc); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
