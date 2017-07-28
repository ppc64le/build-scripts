#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : gromacs 
# Version       : 5.1.2   
# Source repo   : git clone git://git.gromacs.org/gromacs.git    
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
sudo yum group install 'Development Tools' -y

# install dependencies
sudo yum install cuda-cudart-7-5-7.5-23.ppc64le -y
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install zlib-1.2.7-17.el7.ppc64le -y
sudo yum install blas-3.4.2-5.el7.ppc64le -y
sudo yum install lapack-3.4.2-5.el7.ppc64le -y 
sudo yum install libgomp-4.8.5-11.el7.ppc64le -y
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y 
sudo yum install libgfortran-4.8.5-11.el7.ppc64le -y

# download and unpack
wget ftp://ftp.gromacs.org/pub/gromacs/gromacs-5.1.2.tar.gz
tar -xzvf gromacs-5.1.2.tar.gz
cd gromacs-5.1.2

# make
mkdir build
cd build
cmake .. -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON
make
make check
sudo make install
