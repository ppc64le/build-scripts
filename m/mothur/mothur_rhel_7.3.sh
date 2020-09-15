#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : mothur 
# Version       : 1.39.3   
# Source repo   : https://github.com/mothur/mothur/releases      
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
sudo yum install readline-6.2-9.el7.ppc64le -y
sudo yum install boost-iostreams-1.53.0-26.el7.ppc64le -y
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y
sudo yum install ncurses-libs-5.9-13.20130511.el7.ppc64le -y
sudo yum install bzip2-libs-1.0.6-13.el7.ppc64le -y
sudo yum install readline-devel -y
sudo yum install boost* -y

# download and unpack
git clone https://github.com/mothur/mothur.git
cd mothur

# make
sudo make
