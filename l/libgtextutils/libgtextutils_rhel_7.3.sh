#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : libgtextutils
# Version       : 0.7  
# Source repo   : http://hannonlab.cshl.edu/fastx_toolkit/download.html     
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
wget https://github.com/agordon/libgtextutils/releases/download/0.7/libgtextutils-0.7.tar.gz
tar -xzvf libgtextutils-0.7.tar.gz
cd libgtextutils-0.7

# make
./configure --build=ppc64le ; make ; sudo make install
