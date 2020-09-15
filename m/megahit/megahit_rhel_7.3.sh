#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : megahit 
# Version       : v1.1.1-2-g02102e1   
# Source repo   : https://github.com/voutcn/megahit      
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
sudo yum install python -y

# install dependencies
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install zlib-1.2.7-17.el7.ppc64le -y
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y
sudo yum install libstdc++-4.8.5-11.el7.ppc64le -y
sudo yum install libstdc++.ppc64le -y
sudo yum install libstdc++-devel.ppc64le -y
sudo yum install libstdc++-static.ppc64le -y

# download and unpack
git clone https://github.com/voutcn/megahit
cd megahit 

# make
make disablempopcnt=1
