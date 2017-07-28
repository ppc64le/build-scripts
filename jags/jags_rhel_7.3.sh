#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : jags 
# Version       : 4.2.0 
# Source repo   : http://mcmc-jags.sourceforge.net/      
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

sudo yum install lapack-3.4.2-5.el7.ppc64le -y
sudo yum install lapack-static.ppc64le -y
sudo yum install lapack-devel.ppc64le -y

# download and unpack
wget https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/JAGS-4.2.0.tar.gz
tar -xzvf JAGS-4.2.0.tar.gz
cd JAGS-4.2.0

# make
./configure --build=ppc64le
make
sudo make install
