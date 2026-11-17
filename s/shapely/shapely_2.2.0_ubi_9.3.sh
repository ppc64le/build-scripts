#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : shapely
# Version       : 2.2.0
# Source repo   : https://github.com/shapely/shapely.git
# Tested on     : UBI 9.3
# Language      : Python, C, Cython
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : vrushanaik <Vrusha.Naik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Fix known issue with Shapely compilation using gcc-toolset-13(https://bugs.gentoo.org/915056 - found still occurs).
# Note: Currently create_wheel_wrapper.sh pre-installs gcc-toolset-13 that fails Shapely wheel builds in python ecosystem.
yum remove -y gcc-toolset-13
export PATH=${PATH#/opt/rh/gcc-toolset-13/root/usr/bin:}

yum install -y python3.11 python3.11-devel python3.11-pip git gcc-gfortran.ppc64le gcc-c++ cmake
yum install -y openblas-devel openblas
python3.11 -m pip install Cython pytest hypothesis build

HOME_DIR=${PWD}
cd $HOME_DIR

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

cd $HOME_DIR

# Clone the shapely package.
PACKAGE_NAME=shapely
PACKAGE_VERSION=${1:-2.2.0}
PACKAGE_URL=https://github.com/shapely/shapely.git
PACKAGE_DIR=shapely

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$HOME_DIR/geos/build/lib:$LD_LIBRARY_PATH
export GEOS_CONFIG=$HOME_DIR/geos/build/tools/geos-config

chmod +x $GEOS_CONFIG

# Build the package (This is dependent on numpy)
python3.11 -m pip install . 


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

# In Shapely 2.x the tests live inside the package (src/shapely/tests).
# Run them against the installed package from outside the source tree; running from
# within the repo makes pytest import the uncompiled source tree (no shapely.lib).
cd /tmp

# Test the package
python3.11 -m pytest --pyargs shapely.tests.test_predicates

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
