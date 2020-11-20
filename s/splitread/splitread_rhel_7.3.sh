#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : splitread  
# Version       : v0.1 
# Source repo   : http://splitread.sourceforge.net/          
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
sudo yum install glibc-devel-2.17-157.el7.ppc64le -y
sudo yum install glibc-static-2.17-157.el7.ppc64le -y
sudo yum install zlib-devel-1.2.7-17.el7.ppc64le -y
sudo yum install zlib-1.2.7-17.el7.ppc64le -y
sudo yum install zlib-static-1.2.7-17.el7.ppc64le -y

# download and unpack
wget https://downloads.sourceforge.net/project/splitread/SPLITREAD_v0.1.tar.gz
tar -xzvf SPLITREAD_v0.1.tar.gz
cd Code-Release

# make
sh Make.sh
