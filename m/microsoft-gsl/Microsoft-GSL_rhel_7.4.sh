# ----------------------------------------------------------------------------
#
# Package       : Microsoft/GSL
# Version       : 'master'
# Source repo   : https://github.com/Microsoft/GSL.git
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# gcc5.4 is pre-requisite for this package hence install it before running
# this script. 
# ----------------------------------------------------------------------------
#!/bin/bash

WDIR=`pwd`
sudo yum update -y
sudo yum install -y git gcc-c++ make

#build cmake
cd $WDIR
git clone https://gitlab.kitware.com/cmake/cmake.git
cd $WDIR/cmake
git checkout v3.7.2
./bootstrap && make && sudo make install
sudo cp  /usr/local/bin/cmake /usr/bin/cmake
#build GSL
cd $WDIR
git clone --depth=50 https://github.com/Microsoft/GSL.git Microsoft/GSL
cd $WDIR/Microsoft/GSL/
mkdir build
cd $WDIR/Microsoft/GSL/build
cmake .. && cmake --build . && ctest
cd $WDIR
rm -rf cmake
