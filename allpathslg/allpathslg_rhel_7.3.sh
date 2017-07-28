#!/bin/bash
#-----------------------------------------------------------------------------
# 
# package       : allpathslg
# Version       : 52488
# Source repo   : ftp://ftp.broadinstitute.org/pub/crd/ALLPATHS/Release-LG/latest_source_code/LATEST_VERSION.tar.gz 
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

## Update Source
sudo yum update -y

## install deppendencies
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install libgomp-4.8.5-11.el7.ppc64le -y
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y

# download and unpack
wget ftp://ftp.broadinstitute.org/pub/crd/ALLPATHS/Release-LG/latest_source_code/LATEST_VERSION.tar.gz
tar -xzvf LATEST_VERSION.tar.gz
cd allpathslg-52488 

# configure
./configure --prefix=/raid1/home/cgrb/barrants/dev/buildscripts/allpathslg/configloc --build=ppc64le 

# remove flag
sed -i -e 's/-mieee-fp//g' src/Makefile

#make install
make ; sudo make install
