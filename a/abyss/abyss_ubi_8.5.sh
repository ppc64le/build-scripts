#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: abyss
# Version	: v2.3.5
# Source repo	: https://github.com/bcgsc/abyss.git
# Tested on	: UBI: 8.5
# Language      : Go 
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=abyss
PACKAGE_VERSION=${1:-2.3.5}
PACKAGE_URL=https://github.com/bcgsc/abyss.git

yum update -y
yum install -y gcc-c++ glibc sqlite libgcc libgomp git make wget autoconf bzip2

#install sparsehash
git clone https://github.com/sparsehash/sparsehash.git
cd sparsehash/
./configure --build=ppc64le-redhat-linux
make
make install

cd /
dnf makecache
dnf install -y automake

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

wget http://downloads.sourceforge.net/project/boost/boost/1.56.0/boost_1_56_0.tar.bz2
tar jxf boost_1_56_0.tar.bz2

./autogen.sh

mkdir build
cd build/
../configure --prefix=/usr/local/abyss

if ! make; then
        echo "Build fails"
        exit 1
fi

if ! make install; then
        echo "Install fails"
        exit 1
fi

if ! make check; then
        echo "Test Fails"
        exit 2
else
        echo "Build and Test Success"
        exit 0
fi
