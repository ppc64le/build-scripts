#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : GEOS
# Version       : 3.11.1
# Source repo   : https://github.com/libgeos/geos
# Tested on     : UBI 8.5
# Language      : C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=GEOS
PACKAGE_VERSION=${1:-3.11.1}
PACKAGE_URL=https://github.com/libgeos/geos

# Install required dependencies
yum install -y git cmake gcc gcc-c++

git clone https://github.com/libgeos/geos
cd geos
mkdir build
cd build
cmake ..

#Build and test the package
if !(make)
then
  echo "Failed to build the package"
  exit 1
fi

if !(ctest)
then
  echo "Failed to validate the package"
  exit 2
fi

make install