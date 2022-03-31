#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : julia
# Version       : v1.7.2 (master branch, commit:bf534986350a991e4a1b29126de0342ffd76205e)
# Source repo   : https://github.com/JuliaLang/julia/releases/tag/v1.7.2
# Language	    : Julia
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

#currently julia works on power with the following commit(v1.7.2)
JULIA_VERSION=bf534986350a991e4a1b29126de0342ffd76205e

#Install required dependencies
yum update -y
yum install wget expat-devel openssl-devel libcurl-devel tk make gcc gcc-c++ patch bzip2 m4 python38 git -y

SRCDIR=`pwd`
DIRNAME="julia"

#Build gettext
wget  https://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.gz
tar -zxvf gettext-0.21.tar.gz
cd gettext-0.21
./configure
make
make install

#Build cmake from source
cd $SRCDIR
wget https://cmake.org/files/v3.11/cmake-3.11.4.tar.gz
tar -zxvf cmake-3.11.4.tar.gz

cd cmake-3.11.4
./bootstrap --system-curl
make
make install
export PATH=/usr/local/bin:$PATH

#download and build julia
cd $SRCDIR
mkdir -p juliabuild
if [ ! -d "$DIRNAME" ]; then
        git clone https://github.com/JuliaLang/julia julia
fi
cd julia
#currently we will checkout only version 1.7.2
git checkout $JULIA_VERSION
make O=../juliabuild
