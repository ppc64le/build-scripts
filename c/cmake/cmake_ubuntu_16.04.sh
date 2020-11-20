#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : cmake 
# Version       : 3.4.3  
# Source repo   : http://www.cmake.org/files/v3.4/cmake-3.4.3.tar.gz  
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
sudo apt-get install -y cmake 
