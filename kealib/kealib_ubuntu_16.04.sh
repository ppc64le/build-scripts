# ----------------------------------------------------------------------------
#
# Package	: kealib
# Version	: 1.4.6
# Source repo	: https://bitbucket.org/chchrsc/kealib
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y libgdal-dev libproj-dev gdal-bin mercurial \
  build-essential cmake

# Clone source code.
hg clone https://bitbucket.org/chchrsc/kealib
cd kealib/trunk

# Set variables for cmake
cmake -DCMAKE_INSTALL_PREFIX:STRING=/usr
cmake -DGDAL_INCLUDE_DIR:STRING=/usr/include/gdal
cmake -DGDAL_LIB_PATH:STRING=/usr/lib
cmake -DHDF5_INCLUDE_DIR:STRING=/usr/include/hdf5/serial
cmake -DHDF5_LIB_PATH:STRING=/usr/lib/powerpc64le-linux-gnu/hdf5/serial

# Build source code, Install and Run tests.
cmake .
make install
make test
