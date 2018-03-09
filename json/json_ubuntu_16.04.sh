# ----------------------------------------------------------------------------
#
# Package       : json
# Version       : 3.1.1 
# Source repo   : https://github.com/nlohmann/json
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

WDIR=`pwd`
sudo apt-get update -y
sudo apt-get install -y bzip2 git make build-essential wget

cd $WDIR
wget http://www.cmake.org/files/v3.4/cmake-3.4.3.tar.gz
tar -xzvf cmake-3.4.3.tar.gz
cd $WDIR/cmake-3.4.3
./configure && make && sudo make install
cd $WDIR
git clone https://github.com/nlohmann/json
cd $WDIR/json
mkdir build
cd $WDIR/json/build
cmake ..
cmake --build . --config Release
ctest --output-on-failure
