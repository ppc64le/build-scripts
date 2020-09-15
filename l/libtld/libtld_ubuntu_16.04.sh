# ----------------------------------------------------------------------------
#
# Package       : LibTLD 
# Version       : 1.5.9
# Source repo   : https://github.com/m2osw/libtld
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install Dependecies
sudo apt-get update -y
sudo apt-get install -y wget gcc g++ cmake libboost1.58-dev git \
    libboost1.58-tools-dev qt5-default doxygen graphviz graphviz-dev dpkg-dev

# Download Source 
cd $HOME
git clone https://github.com/m2osw/libtld
git clone https://github.com/m2osw/snapcmakemodules.git

# Build and Test
mkdir BUILD && cd BUILD && CMAKE_PREFIX_PATH=../snapcmakemodules/Modules/ cmake -DCMAKE_MODULE_PATH=../snapcmakemodules/Modules ../libtld 
make && sudo make install

# Valid test:
cd src
./validate_tld http://snapwebsites.org/project/libtld
if [ $? -eq 0 ] ; then
  echo "success"
fi
