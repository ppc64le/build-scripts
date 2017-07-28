#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : ncbi-blast 
# Version       : 2.6.0+
# Source repo   : ftp://ftp.ncbi.nlm.nih.gov/blast/executables/LATEST/      
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
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y
sudo yum install libgomp-4.8.5-11.el7.ppc64le -y
sudo yum install zlib-1.2.7-17.el7.ppc64le -y
sudo yum install bzip2-libs-1.0.6-13.el7.ppc64le -y
sudo yum install pcre-8.32-15.el7_2.1.ppc64le -y

# download and unpack
wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/LATEST/ncbi-blast-2.6.0+-src.tar.gz
tar zxvpf ncbi-blast-2.6.0+-src.tar.gz
cd ncbi-blast-2.6.0+-src/c++

# make
./configure --build=ppc64le
cd ReleaseMT/build
make all_r
export PATH=$PATH:$HOME/ncbi-blast-2.2.29+/bin
