#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : cmake 
# Version       : 3.4.3  
# Source repo   : http://www.cmake.org/files/v3.4/cmake-3.4.3.tar.gz  
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
sudo yum install ncurses-libs-5.9-13.20130511.el7.ppc64le -y
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y

# download and unpack
wget http://www.cmake.org/files/v3.4/cmake-3.4.3.tar.gz
tar -xzvf cmake-3.4.3.tar.gz
cd cmake-3.4.3 

# make
./bootstrap && make && sudo make install
