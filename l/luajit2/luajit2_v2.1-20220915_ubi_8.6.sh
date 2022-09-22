#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : luajit2
# Version       : v2.1-20220915
# Source repo   : https://github.com/openresty/luajit2
# Tested on	    : UBI 8.6
# Language      : Lua
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Reynold Vaz <Reynold.Vaz@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=luajit2
PACKAGE_URL=https://github.com/openresty/luajit2.git
PACKAGE_VERSION=${1:-v2.1-20220915}

yum install git make gcc gcc-c++ -y 

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

make
make install