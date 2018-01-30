# ----------------------------------------------------------------------------
#
# Package	: dlib
# Version	: 19.7
# Source repo	: https://github.com/davisking/dlib
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y git wget cmake build-essential libx11-dev unzip

# Clone source code from github.
git clone https://github.com/davisking/dlib
cd dlib

# This is alternate link to get source.
#wget http://dlib.net/files/dlib-19.7.zip
#unzip dlib-19.7.zip
#cd dlib-19.7

# Build dlib.
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# Run unitests.
cd ../dlib/test
mkdir build
cd build
cmake ..
cmake --build . --config Release
./dtest --runall
