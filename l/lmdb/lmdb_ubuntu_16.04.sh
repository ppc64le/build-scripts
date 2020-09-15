# ----------------------------------------------------------------------------
#
# Package	: lmdb
# Version	: 0.9.19
# Source repo	: https://github.com/LMDB/lmdb
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
sudo apt-get install -y build-essential g++ make git

# Build and test source code.
git clone https://github.com/LMDB/lmdb
cd lmdb/libraries/liblmdb
make
make test
sudo make install
