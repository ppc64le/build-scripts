#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : h5py
# Version       : 3.13.0
# Source repo   : https://github.com/h5py/h5py.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=h5py
PACKAGE_VERSION=${1:-3.13.0}
PACKAGE_URL=https://github.com/h5py/h5py.git

yum install -y git make cmake wget python python-devel python-pip zlib zlib-devel openblas
yum install gcc-toolset-13 -y 

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
gcc --version

#Build hdf5 from source
git clone https://github.com/HDFGroup/hdf5
cd hdf5/
git checkout hdf5_1.14.6

 ./configure --prefix=/usr/local/hdf5 --enable-cxx --enable-fortran  --with-pthread=yes --enable-threadsafe  --enable-build-mode=production --enable-unsupported  --enable-using-memchecker  --enable-clear-file-buffers --with-ssl
make -j1
make install

cd ..

#build h5py
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Dependencies installation"

python3 -m pip install Cython==0.29.36
python3 -m pip install numpy==2.0.2
python3 -m pip install pkgconfig pytest-mpi setuptools
python3 -m pip install wheel pytest pytest-mpi tox

echo "export statmenents"
export LD_LIBRARY_PATH=/usr/local/hdf5/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/hdf5/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/hdf5/include:$LD_LIBRARY_PATH
export HDF5_DIR=/usr/local/hdf5

echo "Installation" 

if ! (HDF5_DIR=/usr/local/hdf5 python -m pip install .);then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "Executing the Testcases"
cd ..

if ! (python -m pytest --pyargs h5py -k "not test_append_permissions"); then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
