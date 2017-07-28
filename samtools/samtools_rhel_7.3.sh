#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : samtools  
# Version       : 1.3.1
# Source repo   : https://sourceforge.net/projects/samtools/       
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
src=`pwd`
sudo yum update -y

# gcc dev tools
sudo yum groupinstall 'Development Tools' -y
sudo yum install perl -y

# install dependencies
sudo yum install zlib-1.2.7-17.el7.ppc64le -y
sudo yum install zlib-devel -y
sudo yum install zlib-static -y
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install ncurses-libs-5.9-13.20130511.el7.ppc64le -y
sudo yum install ncurses-devel-5.9-13.20130511.el7.ppc64le -y
sudo yum install automake-1.13.4-3.el7.noarch -y
sudo yum install autoconf-2.69-11.el7.noarch -y
sudo yum install bzip2-devel -y
sudo yum install xz-devel -y

# download and unpack and make samtools
git clone https://github.com/samtools/samtools.git
cd samtools
git clone https://github.com/samtools/htslib.git
autoconf
./configure --build=ppc64le 
sudo make install
cd $src
