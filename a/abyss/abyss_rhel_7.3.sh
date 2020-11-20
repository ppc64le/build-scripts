#!/bin/bash
#-----------------------------------------------------------------------------
# 
# package       : Abyss 
# Version       : 1.9.0 
# Source repo   : https://github.com/bcgsc/abyss/releases/download/1.9.0/abyss-1.9.0.tar.gz
# Tested on     : rhel_7.3
# Script License: Apache License, Version 2 or later 
# Maintainer    : Shane Barrantes <Shane.Barrantes@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintaine" of this script.
#
# ---------------------------------------------------------------------------- 

curdir=`pwd`

## Update Source
sudo yum update -y

#gcc dev tools
sudo yum groupinstall -y 'Development Tools'

#dependencies
sudo yum install -y glibc-2.17-157.el7.ppc64le sqlite-3.7.17-8.el7.ppc64le libgcc-4.8.5-11.el7.ppc64le libgomp-4.8.5-11.el7.ppc64le

#install sparsehash
git clone https://github.com/sparsehash/sparsehash.git
cd sparsehash

# make sparsehash
./configure --build=ppc64le-redhat-linux ; make ; sudo make install

cd $curdir

# download and unpack abyss
wget https://github.com/bcgsc/abyss/releases/download/1.9.0/abyss-1.9.0.tar.gz
tar -xzvf abyss-1.9.0.tar.gz
cd abyss-1.9.0

#install boost
wget http://downloads.sourceforge.net/project/boost/boost/1.56.0/boost_1_56_0.tar.bz2
tar jxf boost_1_56_0.tar.bz2

# make abyss
./configure --build=ppc64le ; make ; sudo make install

cd $curdir
