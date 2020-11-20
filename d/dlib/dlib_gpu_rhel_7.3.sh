# ----------------------------------------------------------------------------
#
# Package	: dlib
# Version	: 19.7
# Source repo	: https://github.com/davisking/dlib
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
# This script should be executed as "root".

# Assumption:
# cuda-9.1.85-1.ppc64le and cudnn-9.1-linux-ppc64le-v7.tgz are installed.
export LIBRARY_PATH=/usr/local/cuda/lib64/stubs

# Required on RHEL/CentOS
yum install -y epel-release
yum update -y
yum install -y git wget bzip2 make gcc-c++ libX11-devel unzip

WDIR=`pwd`

# Need to install latest cmake and g++
wget http://www.cmake.org/files/v3.4/cmake-3.4.3.tar.gz
tar -xzvf cmake-3.4.3.tar.gz
cd cmake-3.4.3
./configure && make
make install
ln -s /usr/local/bin/cmake /usr/bin/cmake
cd $WDIR
rm -rf cmake-3.4.3.tar.gz cmake-3.4.3

wget https://ftp.gnu.org/gnu/gcc/gcc-5.4.0/gcc-5.4.0.tar.gz
tar -xzf gcc-5.4.0.tar.gz
cd gcc-5.4.0
./contrib/download_prerequisites
cd ..
mkdir objdir
cd objdir
$PWD/../gcc-5.4.0/configure --prefix=$HOME/GCC-5.4.0 --enable-languages=c,c++
make
make install

# Do not remove g++ on CentOS as it also removes CUDA.
#yum remove -y gcc gcc-c++
export PATH=/root/GCC-5.4.0/bin:$PATH
export LD_LIBRARY_PATH=/root/GCC-5.4.0/lib:/root/GCC-5.4.0/lib64:$LD_LIBRARY_PATH
cd $WDIR

# Clone source code from github.
git clone https://github.com/davisking/dlib
cd dlib

# Alternate way of obtaining the source.
#wget http://dlib.net/files/dlib-19.7.zip
#unzip dlib-19.7.zip
#cd dlib-19.7

# Build dlib.
mkdir build
cd build
CC=$HOME/GCC-5.4.0/bin/gcc CXX=$HOME/GCC-5.4.0/bin/g++ cmake .. -DCMAKE_BUILD_TYPE=Release
CC=$HOME/GCC-5.4.0/bin/gcc CXX=$HOME/GCC-5.4.0/bin/g++ cmake --build . --config Release

# Run unitests.
cd ../dlib/test
mkdir build
cd build
CC=$HOME/GCC-5.4.0/bin/gcc CXX=$HOME/GCC-5.4.0/bin/g++ cmake ..
CC=$HOME/GCC-5.4.0/bin/gcc CXX=$HOME/GCC-5.4.0/bin/g++ cmake --build . --config Release
./dtest --runall
