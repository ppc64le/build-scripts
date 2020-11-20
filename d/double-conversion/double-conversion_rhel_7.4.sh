# ----------------------------------------------------------------------------
#
# Package	: double-conversion
# Version	: 3.0.0
# Source repo	: https://github.com/google/double-conversion.git
# Tested on	: rhel_7.4
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
sudo yum update -y
sudo yum install -y wget make gcc autoconf automake git python gcc-c++

# Install later version of CMake.
wget http://www.cmake.org/files/v3.4/cmake-3.4.3.tar.gz
tar -xzvf cmake-3.4.3.tar.gz
rm cmake-3.4.3.tar.gz
cd cmake-3.4.3
./configure && make
sudo make install
cd ..

# Clone and build source.
git clone https://github.com/google/double-conversion.git
cd double-conversion
cmake . -DBUILD_TESTING=ON
make
make test
sudo make install
