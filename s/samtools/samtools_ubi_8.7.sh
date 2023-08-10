#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	    : samtools
# Version	    : 1.18
# Source repo	    : https://github.com/samtools/samtools
# Tested on	    : ubi 8.7
# Language          : C
# Travis-Check      : true
# Script License    : Apache License, Version 2 or later
# Maintainer	    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME="samtools"
PACKAGE_VERSION=${1:-"1.18"}
PACKAGE_URL=https://github.com/samtools/samtools

#Install dependencies
#yum -y update
yum install -y git autoconf automake make gcc gcc-c++ perl-Data-Dumper zlib-devel bzip2 bzip2-devel xz-devel curl-devel openssl-devel ncurses-devel diffutils

#clone the repository
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Clone htslib repo and build
git clone https://github.com/samtools/htslib.git
cd htslib
#Run htslib conpile
autoreconf -i
git submodule update --init --recursive
./configure
make
make install
cd ..

#To build and install Samtools
autoreconf -i
./configure
if ! make && make install; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#Test 
if ! make test; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  both_build_and_test_success"
    exit 0
fi
