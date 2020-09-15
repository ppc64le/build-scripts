# ----------------------------------------------------------------------------
#
# Package	: LightGBM
# Version	: 2.1.0
# Source repo	: https://github.com/Microsoft/LightGBM
# Tested on	: centos_7.3
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

sudo yum update -y
sudo yum install -y wget

#Install OpenCL development environment
cd /tmp
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo rpm -ivh epel-release-latest-7.noarch.rpm
sudo yum update -y
sudo yum install -y opencl-filesystem opencl-headers

cd /tmp
wget https://rpmfind.net/linux/epel/7/ppc64le/Packages/o/ocl-icd-2.2.12-1.el7.ppc64le.rpm
sudo rpm -ivh ocl-icd-2.2.12-1.el7.ppc64le.rpm

#Install necessary building tools and dependencies
sudo yum install -y gcc gcc-c++ git vim python python-devel python-setuptools make gcc-gfortran

cd /tmp
wget https://cmake.org/files/v3.10/cmake-3.10.2.tar.gz
tar -zxvf cmake-3.10.2.tar.gz
cd cmake-3.10.2
./configure
make
sudo make install

sudo yum install -y openblas-devel.ppc64le
sudo ln -s /usr/include/openblas/* /usr/include/

cd /tmp
wget http://sourceforge.net/projects/boost/files/boost/1.56.0/boost_1_56_0.tar.gz
tar -zxvf boost_1_56_0.tar.gz
cd boost_1_56_0
./bootstrap.sh --with-libraries=filesystem,program_options,system --exec-prefix=/usr/include
sudo ./b2 install
export BOOST_LIBRARYDIR=/usr/include/lib

cd $HOME
#Compile light GBM with GPU support
git clone --recursive https://github.com/Microsoft/LightGBM
cd LightGBM
mkdir build ; cd build

#Disable altivec support
cmake -DUSE_GPU=1 -DOpenCL_LIBRARY=/usr/lib64/libOpenCL.so.1 -DCMAKE_C_FLAGS="-mno-altivec -mno-vsx" -DCMAKE_CXX_FLAGS="-mno-altivec -mno-vsx" ..
make

#Build the python package
cd ..
wget https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py
sudo pip install --upgrade pip

sudo yum install -y python-numpy
sudo pip install setuptools numpy scipy -U
sudo pip install scikit-learn -U
cd python-package/
sudo python setup.py install --precompile
cd ..

#Execute automated tests
export LD_LIBRARY_PATH=/usr/include/lib
sudo pip install pytest nose pandas
pytest
