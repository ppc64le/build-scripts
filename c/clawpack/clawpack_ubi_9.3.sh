#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package          : clawpack
# Version          : v5.12.0
# Source repo      : https://github.com/clawpack/clawpack
# Tested on        : UBI 9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Anumala Rajesh <Anumala.Rajesh@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

#Variables
PACKAGE_NAME=clawpack
PACKAGE_URL=https://github.com/clawpack/clawpack
PACKAGE_VERSION=${1:-v5.12.0}
CURRENT_DIR=$(pwd)

# Install dependencies
yum install -y python3.11 python3.11-devel python3.11-pip ncurses make cmake python3.11-pytest
yum install -y git gcc-toolset-13 libffi libffi-devel sqlite openssl-devel xz-devel ncurses-devel wget
yum install -y sqlite-devel sqlite-libs bzip2-devel cargo rust graphviz zlib-devel findutils

# Setting Variable for compiler C and C++
export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_HOME/bin:$PATH
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++

yum install -y libjpeg-turbo-devel freetype-devel libwebp-devel

python3.11 -m pip install numpy pytest nose matplotlib coverage pytest-cov packaging 

cd $CURRENT_DIR

#installing pillow
echo " ----------------------------------- Pillow Installing ----------------------------------- "

git clone https://github.com/python-pillow/Pillow
cd Pillow
git checkout 11.1.0

yum install -y libjpeg-turbo libjpeg-turbo-devel
git submodule update --init

python3.11 -m pip install .

echo " ----------------------------------- Pillow Successfully Installed ----------------------------------- "

cd $CURRENT_DIR

#Build hdf5 from source
echo " ----------------------------------- Hdf5 Installing ----------------------------------- "

git clone https://github.com/HDFGroup/hdf5
cd hdf5/
git checkout hdf5-1_12_1

git submodule update --init
yum install -y zlib zlib-devel

mkdir hdf5_prefix
export HDF5_PREFIX=$(pwd)/hdf5_prefix

./configure --prefix=$HDF5_PREFIX --enable-cxx --enable-fortran  --with-pthread=yes --enable-threadsafe  \
    --enable-build-mode=production --enable-unsupported --enable-using-memchecker  --enable-clear-file-buffers --with-ssl

make
make install PREFIX="${HDF5_PREFIX}"

export LD_LIBRARY_PATH=${HDF5_PREFIX}/lib:$LD_LIBRARY_PATH
echo " ----------------------------------- Hdf5 Successfully Installed ----------------------------------- "

cd $CURRENT_DIR

#Build h5py from source
echo " ----------------------------------- H5py Installing ----------------------------------- "

git clone https://github.com/h5py/h5py.git
cd h5py/
git checkout 3.13.0

export HDF5_DIR=$HDF5_PREFIX
export CFLAGS="-I$HDF5_DIR/include"
export LDFLAGS="-L$HDF5_DIR/lib"
export LD_LIBRARY_PATH=$HDF5_DIR/lib:$LD_LIBRARY_PATH

# Install Python build tools
python3.11 -m pip install --upgrade pip setuptools wheel cython packaging

# Build wheel
python3.11 setup.py bdist_wheel

# Install from the built wheel
python3.11 -m pip install dist/h5py-*.whl

# python3.11 -m pip install .
cd $CURRENT_DIR

python3.11 -c "import h5py; print(h5py.__version__)"

echo " ----------------------------------- H5py Successfully Installed ----------------------------------- "

cd $CURRENT_DIR

echo " ----------------------------------- Clawpack Cloning ----------------------------------- "

git clone $PACKAGE_URL -b $PACKAGE_VERSION
cd $PACKAGE_NAME
git submodule init
git submodule update

# Set Clawpack environment variables
export CLAW=$(pwd)
export GEOCLAW=$CLAW/geoclaw
export RIEMANN=$CLAW/riemann
export CLAWUTIL=$CLAW/clawutil
export AMRCLAW=$CLAW/amrclaw

export PYTHONPATH=$CLAW:$PYTHONPATH
export PATH=$CLAW/clawutil/src:$PATH

export FC=gfortran

# Instaling Dependencies
python3.11 -m pip install -r requirements-dev.txt 
python3.11 -m pip install pynose nose 
python3.11 setup.py git-dev
if python3.11 -m pip install . ; then
    echo "  ----------------------------------- $PACKAGE_NAME : Install_Success ----------------------------------- "
    echo "$PACKAGE_NAME $PACKAGE_URL"
    echo "  $PACKAGE_NAME  |  $PACKAGE_URL  |  $PACKAGE_VERSION  |  GitHub  |  Pass  |  Install Success  "
else
    echo "  ----------------------------------- $PACKAGE_NAME : Install_Failed ----------------------------------- "
    echo "$PACKAGE_NAME $PACKAGE_URL"
    echo "  $PACKAGE_NAME  |  $PACKAGE_URL  |  $PACKAGE_VERSION  |  GitHub  |  Fail  |  Install Failed  "
    exit 1
fi 

# Skipping test block No proper test folder found for running tests.