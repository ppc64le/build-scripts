# ----------------------------------------------------------------------------
#
# Package       : psqlodbc
# Version       : 1.16.1
# Source repo   : https://github.com/Distrotech/psqlodbc.git
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y unixodbc unixodbc-dev libpq-dev git make g++ \
    build-essential autoconf

# Clone source
git clone https://github.com/Distrotech/psqlodbc.git
cd $PWD/psqlodbc

## Build and Install
./bootstrap
./configure --build=ppc64le-linux
make
make check
