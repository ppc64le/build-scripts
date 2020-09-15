#!/bin/bash
#-----------------------------------------------------------------------------
#
# Package       : sparsehash
# Version       : 2.0.3
# Source repo   : https://github.com/sparsehash/sparsehash.git
# Tested on     : rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Shane Barrantes <Shane.Barrantes@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintaine" of this script.
#
# ---------------------------------------------------------------------------- 

curdir=`pwd`

# Update Source
sudo yum update -y

# gcc dev tools
sudo yum groupinstall 'Development Tools' -y

# download and unpack
git clone https://github.com/sparsehash/sparsehash.git
cd sparsehash

# make
./configure --build=ppc64le-redhat-linux
make
sudo make install
cd $curdir
