#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : shapely
# Version       : 1.8.5
# Source repo   : https://github.com/shapely/shapely.git
# Tested on     : UBI 9.3
# Language      : Python, C, Cython
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandan.Abhyankar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

yum install -y python311 python3.11-devel python3.11-pip git gcc-gfortran.ppc64le gcc-c++ cmake
yum install -y openblas-devel openblas
pip3.11 install Cython pytest hypothesis build

# Install GEOS dependencies (Version 3.11.1)
git clone https://github.com/libgeos/geos
cd geos
git checkout 3.11.1
mkdir build
cd build
cmake ..

# Build and test the package
if !(make)
then
  echo "Failed to build the dependent GEOS package"
  exit 1
fi

if !(ctest)
then
  echo "Failed to validate the dependent GEOS package"
  exit 1
fi

make install

# Clone the shapely package.
cd ../../
PACKAGE_NAME=shapely
PACKAGE_VERSION=${1:-1.8.5}
PACKAGE_URL=https://github.com/shapely/shapely.git

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init

export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:/geos/build/lib:/usr/lib:/usr/lib64:$LD_LIBRARY_PATH
export GEOS_CONFIG=/geos/build/tools/geos-config

# Build the package (This is dependent on numpy)
python3.11 -m pip install -e .

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Build_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Build_Success"
else
     echo "------------------$PACKAGE_NAME::Build_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Build_Fail"
     exit 1
fi

# Test the package
python3.11 -m pytest tests/test_geometry_base.py

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi

