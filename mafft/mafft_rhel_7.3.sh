#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : mafft
# Version       : 6.956-with-extensions  
# Source repo   : http://mafft.cbrc.jp/alignment/software/mafft-6.956-with-extensions-src.tgz     
# Tested on     : rhel 7.3
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
wget http://mafft.cbrc.jp/alignment/software/mafft-7.310-with-extensions-src.tgz
tar -xzvf mafft-7.310-with-extensions-src.tgz
cd mafft-7.310-with-extensions

# make
cd core
make
make clean
sudo make install
