#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : clearcut 
# Version       : 1.0.9
# Source repo   : https://github.com/ibest/clearcut
# Tested on     : ubuntu_16.04 
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
# The clearcut installation provided in this script has not been fully optimized.
# To see how to optimize read the clearcut readme file

## Update Source
sudo apt-get update -y

#gcc dev tools
sudo apt-get install -y build-essential
sudo apt-get install -y zlib1g-dev

# download and unpack
git clone https://github.com/ibest/clearcut.git
cd clearcut

# make
make
