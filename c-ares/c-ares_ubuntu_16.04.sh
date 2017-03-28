# ----------------------------------------------------------------------------
#
# Package	: c-ares
# Version	: 1.12.0
# Source repo	: https://github.com/bagder/c-ares.git
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
sudo apt-get install -y git libtool libtool-bin automake build-essential

# Build c-ares.
git clone https://github.com/bagder/c-ares.git
cd c-ares
./buildconf && ./configure && make

# Run tests.
cd test
make && ./arestest
