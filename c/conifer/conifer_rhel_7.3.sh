#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : conifer 
# Version       : v0.2.2 
# Source repo   : NA
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

# install python
sudo yum install python-2.7.5-48.el7.ppc64le -y
sudo yum install python-h5py.ppc64le -y

#anaconda and dependencies
#wget https://repo.continuum.io/archive/Anaconda2-4.4.0-Linux-ppc64le.sh
#bash Anaconda2-4.4.0-Linux-ppc64le.sh -b
#conda install libgfortran -y

# download and unpack
sudo wget https://downloads.sourceforge.net/project/conifer/CoNIFER%200.2.2/conifer_v0.2.2.tar.gz
sudo tar -xzvf conifer_v0.2.2.tar.gz
cd conifer_v0.2.2d $curdir
