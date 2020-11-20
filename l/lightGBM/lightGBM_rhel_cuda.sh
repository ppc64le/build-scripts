# ----------------------------------------------------------------------------
#
# Package	: LightGBM
# Version	: 2.2.4
# Source repofor lightgbm 	: https://github.com/bordaw/H2O-LightGBM-CUDA
# Maintainer	: Rajesh Bordawekar <bordaw@us.ibm.com>
# Source this script	: https://raw.githubusercontent.com/harinreddy/build-scripts/master/lightGBM/lightGBM_rhel_cuda.sh
# Maintainer	: Hari Reddy <hnreddy@us.ibm.com>
# Tested on	: RHEL_7.6  
# Script License: Apache License, Version 2 or later
#
# Disclaimer: This script has been tested in non-root mode with sudo capability  on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# This script builds H2O-LightGBM-CUDA package maintianed in https://github.com/bordaw/H2O-LightGBM-CUDA
# Prerequisites:  Nvidia CUDA 10.0
# 



#!/bin/bash
set -x
export PATH=/usr/local/bin:$PATH
export CUDACXX=/usr/local/cuda/bin/nvcc

WORK=/tmp

sudo yum install -y wget

#Install necessary building tools and dependencies
#sudo yum install -y gcc gcc-c++ git vim  make gcc-gfortran
sudo yum install -y gcc gcc-c++ git vim make gcc-gfortran

#
# Install cmake-3.12.3
#
cd $WORK
wget https://cmake.org/files/v3.12/cmake-3.12.3.tar.gz
tar -xvf cmake-3.12.3.tar.gz
cd cmake-3.12.3
./bootstrap --prefix=/usr/local
make
sudo make install
#
# Download and build H2O-LightGBM-CUDA 
#
cd $HOME
#Compile light GBM with CUDA support 
git clone --recursive https://github.com/bordaw/H2O-LightGBM-CUDA.git
cd H2O-LightGBM-CUDA
rm -rf build; mkdir build ; cd build
export PATH=/usr/local/bin:$PATH
export CUDACXX=/usr/local/cuda/bin/nvcc
export CC='gcc -O3 '
export CXX='g++ -O3'
 cmake ..   -DUSE_GPU=1
 make

#
#  The folllowing is optional, please comment if this is not needed
#
#

#Build the python package

cd $HOME
#      Compile and install Python

wget https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tgz
tar -xvf Python-3.6.4.tgz
cd Python-3.6.4
sudo yum install openssl-devel readline-devel ncurses-devel bzip2-devel gdbm-devel libsqlite3x-devel zlib-devel lzma-sdk-devel tk-devel xz-devel
./configure --prefix=/usr/local/python3.6.4
make -j 40
sudo make -j 20 install
cd /usr/local/python3.6.4/bin
sudo ln -s python3 python
sudo ln -s pip3 pip
sudo ./pip install --upgrade pip
sudo /usr/local/python3.6.4/bin/pip install wheel

sudo /usr/local/python3.6.4/bin/pip install numpy 
sudo /usr/local/python3.6.4/bin/pip install Cython
sudo /usr/local/python3.6.4/bin/pip install scikit_learn==0.21.3
sudo /usr/local/python3.6.4/bin/pip install  scipy==1.3.1


sudo yum install lapack
sudo yum install lapack-devel

cd $HOME/H2O-LightGBM-CUDA/python-package/
sudo rm -rf dist build compile
sudo /usr/local/python3.6.4/bin/pip uninstall lightgbm
sudo /usr/local/python3.6.4/bin/python setup.py sdist bdist_wheel
sudo /usr/local/python3.6.4/bin/pip install dist/lightgbm-2.2.4-py3-none-any.whl
