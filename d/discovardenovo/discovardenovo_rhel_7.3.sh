#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : discovardenovo 
# Version       : 52488 
# Source repo   : https://software.broadinstitute.org/software/discovar/blog/?page_id=98   
# Tested on     : rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Shane Barrantes <shane.barrantes@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintaine" of this script.
#
# ---------------------------------------------------------------------------- 

# Update Source
sudo yum update -y

# gcc dev tools
sudo yum groupinstall 'Development Tools' -y

# install dependencies
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install libgomp-4.8.5-11.el7.ppc64le -y
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y
sudo yum install zlib-1.2.7-17.el7.ppc64le -y
sudo yum install jemalloc-3.6.0-1.el7.ppc64le -y
sudo yum install jemalloc-devel.ppc64le -y
sudo yum install jemalloc.ppc64le -y

# download and unpack
wget ftp://ftp.broadinstitute.org/pub/crd/DiscovarDeNovo/latest_source_code/LATEST_VERSION.tar.gz
tar -xzvf LATEST_VERSION.tar.gz
cd discovardenovo-52488
./configure --build=ppc64le 
sed -i "123s/-mieee-fp/ /" Makefile
sed -i "313s/-mieee-fp/ /" src/Makefile

# make
sudo make all ; sudo make install
