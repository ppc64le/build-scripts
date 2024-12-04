#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : h5py
# Version       : 3.7.0
# Source repo   : https://github.com/h5py/h5py.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=h5py
PACKAGE_VERSION=${1:-3.7.0}
PACKAGE_URL=https://github.com/h5py/h5py.git

# Install dependencies and tools.
yum install -y wget gcc gcc-c++ gcc-gfortran git make  python-devel  openssl-devel unzip 

#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install hdf5
 wget https://github.com/HDFGroup/hdf5/archive/hdf5-1_10_6.zip
 unzip hdf5-1_10_6.zip
 cd hdf5-hdf5-1_10_6
  ./configure --prefix=/usr/local
  make
  make install
export LD_LIBRARY_PATH=/usr/local/hdf5/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
cd ..
   
#install cython
pip install cython==0.29.21 numpy==1.19.5 pkgconfig

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
