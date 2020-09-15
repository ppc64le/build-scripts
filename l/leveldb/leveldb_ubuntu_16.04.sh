# ----------------------------------------------------------------------------
#
# Package       : LevelDB
# Version       : 1.20
# Source repo   : https://github.com/google/leveldb
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

# Install Dependencies
sudo apt-get update -y
sudo apt-get install -y build-essential g++ make libsnappy-dev git

# Build cmake from source, as leveldb needs latest version
cd $HOME
git clone https://github.com/Kitware/CMake.git
cd CMake/
./bootstrap && make && sudo make install

# Set Environment to use latest cmake built
export PATH=$PATH:$HOME/CMake/bin

# Download source and build
cd $HOME
git clone https://github.com/google/leveldb
cd leveldb/
mkdir build
cd build
cmake ..
cmake --build .
ctest --verbose
