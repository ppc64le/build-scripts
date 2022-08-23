#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : LuaJIT2-openresty
# Version          : Luajit2-v2.1.0-beta3
# Source repo      : https://github.com/openresty/luajit2.git
# Tested on        : UBI 8.5
# Language         : C
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

PACKAGE_NAME="LuaJIT2-openresty"
PACKAGE_VERSION=${1:-v2.1.0-beta3}
PACKAGE_URL="https://github.com/openresty/luajit2.git"
yum update -y --allowerasing --nobest
yum install -y vim cmake make git gcc-c++ perl patch
OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`
HOME_DIR=`pwd`

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME || exit 1
git checkout "$PACKAGE_VERSION"

git apply ../luajit2_v2.1.0-beta3.patch 

if ! make && make install ; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi
