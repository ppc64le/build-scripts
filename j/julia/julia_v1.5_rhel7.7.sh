# ----------------------------------------------------------------------------
#
# Package       : julia
# Version       : v1.7.2 (master branch, commit bf534986350a991e4a1b29126de0342ffd76205e)
# Source repo   :
# Tested on     : RHEL 7.7
# Script License: Apache License Version 2.0
# Maintainer    : Amit Shirodkar<amit.shirodkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# FIXME : the automated tests still fail in the master branch

if [ $# -ne 1 ]; then
    echo "missing argument: julia VERSION to build"
    exit 1
fi

#JULIA_VERSION=$1
# FIXME: currently julia works on power with the following commit, 
# TODO: enable other versions as they get supported/fixed
JULIA_VERSION=bf534986350a991e4a1b29126de0342ffd76205e

#Install required dependencies
sudo yum update -y
sudo yum install wget expat-devel openssl-devel libcurl-devel tk gettext-devel make gcc gcc-c++ patch bzip2 m4 -y

SRCDIR=`pwd`
BUILDDIR=`pwd`/builds/julia-build

mkdir $SRCDIR
mkdir -p $BUILDDIR

#Build git2 from source
wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.25.1.tar.gz
tar -zxvf git-2.25.1.tar.gz
cd git-2.25.1
make
sudo make install

#Build cmake from source
cd $SRCDIR
wget https://cmake.org/files/v3.11/cmake-3.11.4.tar.gz
tar -zxvf cmake-3.11.4.tar.gz
cd cmake-3.11.4
./bootstrap --system-curl
make
sudo make install
export PATH=/usr/local/bin:$PATH

#download and build julia
cd $SRCDIR
git clone https://github.com/JuliaLang/julia julia
cd julia 
#currently we will checkout only version 1.7.2
git checkout $JULIA_VERSION
make O=$BUILDDIR configure
cd $BUILDDIR
make
ls -l julia

#add julia bin to $PATH
export PATH=$BUILDDIR/usr/bin:$PATH

