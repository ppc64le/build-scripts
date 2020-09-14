# ----------------------------------------------------------------------------
#
# Package	: mongo-cxx-driver
# Version	: 1.1.0
# Source repo	: https://github.com/mongodb/mongo-cxx-driver.git
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

export CFLAGS="-Wno-error"
export CXXFLAGS="-Wno-error"

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y gcc g++ automake autoconf libtool make wget \
    build-essential git scons python libboost-all-dev

# Build and test code.
git clone -b legacy https://github.com/mongodb/mongo-cxx-driver.git
cd mongo-cxx-driver
sudo git checkout legacy-1.1.0 && scons --extrapath=/usr/local/include/boost --disable-warnings-as-errors install
scons build-unit --disable-warnings-as-errors
scons unit --disable-warnings-as-errors
