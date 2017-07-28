#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : Csdp
# Version       : 6.1.1  
# Source repo   : https://projects.coin-or.org/Csdp/    
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
sudo yum install lapack-3.4.2-5.el7.ppc64le -y
sudo yum install lapack-devel.ppc64le -y
sudo yum install lapack-static.ppc64le -y
sudo yum install blas-devel.ppc64le -y
sudo yum install blas-static.ppc64le -y
sudo yum install blas-3.4.2-5.el7.ppc64le -y
sudo yum install libgfortran-4.8.5-11.el7.ppc64le -y
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y

# download and unpack
wget http://www.coin-or.org/download/source/Csdp/Csdp-6.1.1.tgz
tar -xzvf Csdp-6.1.1.tgz
cd Csdp-6.1.1

export LD_LIBRARY_PATH=/usr/lib64/

# make
make ; sudo make install
