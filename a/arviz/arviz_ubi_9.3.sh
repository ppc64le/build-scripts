#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : arviz
# Version       : v0.18.0
# Source repo   : https://github.com/arviz-devs/arviz.git
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
PACKAGE_NAME=arviz
PACKAGE_VERSION=${1:-v0.18.0}
PACKAGE_URL=https://github.com/arviz-devs/arviz.git

# Install dependencies and tools.
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel wget xz zlib-devel openblas-devel gcc-gfortran.ppc64le libjpeg-devel cmake

#This package required python version >=3.10
# Get the current Python version
current_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "Current Python version: $current_version"

# Check if current python version is greater than or equal to 3.10.
if python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)"; then
    echo "Python version is $current_version, which is 3.10 or greater."
else
    echo "Python version is $current_version, which is less than 3.10."
    echo "Installing Python 3.10..."

    # Download and install Python 3.10
    wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tar.xz
    tar xf Python-3.10.0.tar.xz
    cd Python-3.10.0
    ./configure --prefix=/usr/local --enable-optimizations
    make -j4
    make install
    python3.10 --version
    cd ..
    ln -sf $(which python3.10) /usr/bin/python3
fi


#installing hdf5 and h5py
wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.8/src/hdf5-1.10.8.tar.gz
tar -xvzf hdf5-1.10.8.tar.gz
cd hdf5-1.10.8
./configure --prefix=/usr/local
make
make install
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
pip3 install --no-binary=h5py h5py
cd ..

#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install all dependencies
pip3 install .
pip3 install scipy
	 
#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
