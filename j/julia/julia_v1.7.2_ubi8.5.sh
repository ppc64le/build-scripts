#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : julia
# Version       : v1.7.2
# Source repo   : https://github.com/JuliaLang/julia
# Language      : Julia
# Tested on     : UBI 8.5
# Script License: Apache License Version 2.0
# Travis-Check  : True
# Maintainer    : Pranav Pandit <pranav.pandit1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

SRCDIR=`pwd`
PACKAGE_NAME=julia
PACKAGE_VERSION=${1:-v1.7.2}
PACKAGE_URL=https://github.com/JuliaLang/julia
BLDDIR=juliabuild

#Install required dependencies
yum update -y
yum install wget expat-devel openssl-devel libcurl-devel tk make gcc gcc-c++ patch bzip2 m4 python38 git -y

#Build gettext
wget  https://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.gz
tar -zxvf gettext-0.21.tar.gz
cd gettext-0.21
./configure
make
make install

#download and build julia
cd $SRCDIR
mkdir -p $BLDDIR
if [ ! -d "$PACKAGE_NAME" ]; then
        git clone $PACKAGE_URL
fi
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
make O=../juliabuild
