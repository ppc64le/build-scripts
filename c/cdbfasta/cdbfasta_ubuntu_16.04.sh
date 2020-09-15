#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : cdbfasta 
# Version       : 1.9.0 
# Source repo   : https://downloads.sourceforge.net/project/cdbfasta/cdbfasta.tar.gz
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

## Update Source
sudo apt-get update -y

#gcc dev tools
sudo apt-get install -y build-essential
sudo apt-get install -y zlib1g-dev
# download and unpack
wget https://downloads.sourceforge.net/project/cdbfasta/cdbfasta.tar.gz
tar -xzvf cdbfasta.tar.gz

# make
cd cdbfasta
make
