# ----------------------------------------------------------------------------
#
# Package       : json
# Version       : 3.1.1
# Source repo   : https://github.com/nlohmann/json
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# NOTE : gcc5.5 is pre-requisite for this package. Please install
#        it before running the script. 
#
# ----------------------------------------------------------------------------
#!/bin/bash

WDIR=`pwd`

sudo yum update -y
sudo yum install -y wget gcc-c++ bzip2 git make

cd $WDIR
wget http://www.cmake.org/files/v3.4/cmake-3.4.3.tar.gz
tar -xzvf cmake-3.4.3.tar.gz
cd $WDIR/cmake-3.4.3
./configure && make
sudo make install

cd $WDIR
git clone https://github.com/nlohmann/json
cd $WDIR/json
mkdir build
cd $WDIR/json/build
cmake ..
cmake --build . --config Release
ctest --output-on-failure
