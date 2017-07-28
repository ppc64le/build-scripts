#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : velvet
# Version       : 1.2.09 
# Source repo   : https://www.ebi.ac.uk/~zerbino/velvet/velvet_1.2.09.tgz           
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
sudo yum groupinstall 'Development Tools'

# install dependencies
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install zlib-1.2.7-17.el7.ppc64le -y

# download and unpack
wget https://www.ebi.ac.uk/~zerbino/velvet/velvet_1.2.09.tgz
tar -xzvf velvet_1.2.09.tgz
cd velvet_1.2.09

# make
make
