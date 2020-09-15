# ----------------------------------------------------------------------------
#
# Package	: leveldb
# Version	: 1.20
# Source repo	: https://github.com/google/leveldb
# Tested on	: rhel_7.3
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
sudo yum install -y git gcc-c++ gcc wget make python yum-utils
WDIR=`pwd`

# Latest cmake is required.
git clone https://github.com/Kitware/CMake.git
cd CMake
./bootstrap
make
sudo make install

cd $WDIR
# Clone and build code.
git clone https://github.com/google/leveldb
cd leveldb
mkdir build
cd build
cmake ..
# There is some RHEL specific issue with LEVELDB_IS_BIG_ENDIAN.
# Hence this temporary fix is required on RHEL only.
sed -i -e 's/static const bool kLittleEndian = !LEVELDB_IS_BIG_ENDIAN;/#define LEVELDB_IS_BIG_ENDIAN 0\nstatic const bool kLittleEndian = !LEVELDB_IS_BIG_ENDIAN;/' /home/tom/leveldb/port/port_posix.h
cmake --build .
ctest --verbose

# leveldb changed it's build mechanism from plain make to cmake.
# Older versions may still need following build procedure.
#git clone https://github.com/google/leveldb
#cd leveldb
#make
#sudo ldconfig
#make check
