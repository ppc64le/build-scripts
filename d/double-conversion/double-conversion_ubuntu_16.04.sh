# ----------------------------------------------------------------------------
#
# Package	: double-conversion
# Version	: 3.0.0
# Source repo	: https://github.com/google/double-conversion.git
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

sudo apt-get update -y
sudo apt-get install -y make gcc autoconf automake git python \
    scons g++ cmake

git clone https://github.com/google/double-conversion.git
cd double-conversion
sudo scons install
cmake . -DBUILD_TESTING=ON
make
sudo make install
