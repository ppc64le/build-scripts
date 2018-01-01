# ----------------------------------------------------------------------------
#
# Package	: parquet-cpp
# Version	: 1.3.1
# Source repo	: https://github.com/apache/parquet-cpp
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

#Install dependencies
sudo yum update -y
sudo yum groupinstall 'Development Tools' -y 
sudo yum install -y boost-filesystem boost-program-options \ 	boost-regex boost-system boost-test libtool bison \
	flex pkgconfig git openssl-devel cmake boost-devel \
	wget tar libcurl-devel which

export CXX=g++
export CC=gcc

#Build and install cmake from source (as a version higher than the default #version on RHEL is required)
cd $HOME
wget http://www.cmake.org/files/v3.10/cmake-3.10.1.tar.gz
tar -xzvf cmake-3.10.1.tar.gz
cd cmake-3.10.1 && ./bootstrap --system-curl && make && sudo make install

#Clone and build the source
cd $HOME
git clone https://github.com/apache/parquet-cpp
cd parquet-cpp/
export PARQUET_TEST_DATA=`pwd`/data
mkdir build
cd build
cmake ..
make
ctest -VV -L unittest
