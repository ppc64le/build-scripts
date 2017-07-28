#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : snap 
# Version       : 1.2.09  
# Source repo   : http://korflab.ucdavis.edu/software.html          
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

# download and unpack
wget http://korflab.ucdavis.edu/Software/snap-2013-11-29.tar.gz
tar -xzvf snap-2013-11-29.tar.gz
cd snap

# make
make
