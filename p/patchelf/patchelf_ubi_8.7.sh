#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : patchelf
# Version          : 0.18.0
# Source repo      : https://github.com/NixOS/patchelf
# Tested on        : UBI 8.7
# Language         : C,C++
# Ci-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=patchelf
PACKAGE_VERSION=${1:-0.18.0}
PACKAGE_URL=https://github.com/NixOS/patchelf

HOME_DIR=${PWD}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y python3.11 python3.11-devel diffutils make maven git sudo wget gcc-c++ apr-devel perl openssl-devel automake autoconf libtool libarchive libstdc++-static libstdc++-devel

cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

./bootstrap.sh
./configure
make

if ! make install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make check ; then
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
