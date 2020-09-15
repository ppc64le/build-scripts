#!/bin/bash
#-----------------------------------------------------------------------------
# 
# package       : canu
# Version       : 1.2
# Source repo   : https://github.com/marbl/canu.git 
# Tested on     : Ubuntu_16.04 
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

## Update Source
sudo apt-get update

#gcc dev tools
sudo apt-get install -y build-essential
sudo apt-get install -y libboost-dev

# download and unpack
git clone https://github.com/marbl/canu.git
cd canu/src
make
