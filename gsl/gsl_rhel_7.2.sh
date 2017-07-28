#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : gsl
# Version       : 2.1
# Source repo   : https://ftp.gnu.org/gnu/gsl/     
# Tested on     : rhel 7.2
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

# download and unpack
wget https://ftp.gnu.org/gnu/gsl/gsl-2.1.tar.gz
tar -xzvf gsl-2.1.tar.gz
cd gsl-2.1

# make
./configure --build=ppc64le ; make ; sudo make install
