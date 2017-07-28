#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : htslib
# Version       : 1.5-5-gda5c0c7
# Source repo   : https://github.com/samtools/htslib.git     
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

# install perl
sudo yum install perl -y

# install dependencies
sudo yum install zlib-1.2.7-17.el7.ppc64le -y
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install automake-1.13.4-3.el7.noarch -y
sudo yum install autoconf-2.69-11.el7.noarch -y
sudo yum install bzip2-devel -y
sudo yum install xz-devel -y

# download and unpack and make HTSlib
git clone https://github.com/samtools/htslib.git
cd htslib
autoheader
autoconf
./configure --build=ppc64le
make
sudo make install
