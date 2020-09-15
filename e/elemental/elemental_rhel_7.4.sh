# ----------------------------------------------------------------------------
#
# Package       : elemental
# Version       : 0.87.7
# Source repo   : https://github.com/elemental/Elemental/releases
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Build and install cmake and gcc from source
sudo yum update -y
sudo yum install -y git wget bzip2 gcc-c++ libX11-devel unzip make

wget http://www.cmake.org/files/v3.4/cmake-3.4.3.tar.gz
tar -xzvf cmake-3.4.3.tar.gz
cd cmake-3.4.3
./configure && make
sudo make install

cd $HOME
wget https://ftp.gnu.org/gnu/gcc/gcc-5.4.0/gcc-5.4.0.tar.gz
tar -xzvf gcc-5.4.0.tar.gz
cd gcc-5.4.0
./contrib/download_prerequisites
cd ..
mkdir objdir
cd objdir
$PWD/../gcc-5.4.0/configure --prefix=$HOME/GCC-5.4.0 --enable-languages=c,c++,fortran
make
sudo make install

sudo yum remove -y gcc gcc-c++

export PATH=/root/GCC-5.4.0/bin:$PATH
export LD_LIBRARY_PATH=/root/GCC-5.4.0/lib:/root/GCC-5.4.0/lib64:$LD_LIBRARY_PATH

#Install additional dependencies required for Elemental
sudo yum install -y openmpi-devel

wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
sudo yum update -y
sudo yum install -y openblas-devel lapack-devel

#Set the required environment variables
export MPI=openmpi
export F77=gfortran
export CC=gcc
export CXX=g++
export OPENBLAS_NUM_THREADS=1
export PATH=$PATH:/usr/lib64/openmpi/bin

#Clone, build and test
cd $HOME
git clone https://github.com/elemental/Elemental
cd Elemental
git submodule update --init --recursive

mkdir build && cd build; cmake -DEL_TESTS=ON -DEL_EXAMPLES=ON -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_C_COMPILER=$CC -DCMAKE_Fortran_COMPILER=$F77 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=~/Install ..

make -j2 && sudo make install && ctest --output-on-failure
