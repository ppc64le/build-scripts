#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : egglib
# Version       : 2.1.11 
# Source repo   : Na
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

# download and unpack
wget https://sourceforge.net/projects/egglib/files/2.1.11/egglib-cpp-2.1.11.tar.gz
tar -xzvf egglib-cpp-2.1.11.tar.gz
cd egglib-cpp-2.1.11

# make
sh configure
make
sudo make install
