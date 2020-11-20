#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : discovardenovo 
# Version       : 1.0.0.0 
# Source repo   : http://drfast.sourceforge.net/    
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

# Update Source
sudo apt-get update -y

# gcc dev tools
sudo apt-get install -y build-essential
sudo apt-get install -y zlib1g-dev

# download and unpack
wget https://downloads.sourceforge.net/project/drfast/drFAST.1.0.0.0/drFAST-1.0.0.0.zip
unzip drFAST-1.0.0.0.zip
cd drFAST-1.0.0.0

# make
make
