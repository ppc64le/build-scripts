# ----------------------------------------------------------------------------
#
# Package	: jsoncpp
# Version	: 1.8.4
# Source repo	: https://github.com/open-source-parsers/jsoncpp.git
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
sudo yum install -y wget git gcc python gcc-c++ make which

# Install CMake 3.1 or later.
wget http://www.cmake.org/files/v3.4/cmake-3.4.3.tar.gz
tar -xzvf cmake-3.4.3.tar.gz
rm cmake-3.4.3.tar.gz
cd cmake-3.4.3
./configure && make
sudo make install
cd ..

# Clone and build source.
git clone https://github.com/open-source-parsers/jsoncpp.git
cd jsoncpp
python amalgamate.py
mkdir -p build/debug
cd build/debug

cmake -DCMAKE_BUILD_TYPE=debug -DBUILD_STATIC_LIBS=ON \
  -DBUILD_SHARED_LIBS=OFF -DARCHIVE_INSTALL_DIR=. -G "Unix Makefiles" ../..
make
sudo make install
