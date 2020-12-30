
# ----------------------------------------------------------------------------
#
# Package       : sysdig
# Version       : 0.27.1
# Source repo   : https://github.com/draios/sysdig.git
# Tested on     : Ubuntu 18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Shirodkar <amit.shirodkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the platform
# ==========  as specified, and the version of the package as indicated.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such casea, please
#             contact the "Maintainer" of this script.
#
# ----------------------------------------------------------------------------




apt-get update 
apt-get install build-essential -y
apt-get install git wget libssl-dev pkg-config unzip -y 

apt-get install rpm linux-headers-$(uname -r) libelf-dev -y

wget https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4.tar.gz
tar -xzf cmake-3.16.4.tar.gz
cd cmake-3.16.4
./bootstrap --prefix=/usr
make
make install
cd ..

git clone https://github.com/draios/sysdig.git
cd sysdig
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=$BUILD_TYPE
make VERBOSE=1

make package
make run-unit-tests
