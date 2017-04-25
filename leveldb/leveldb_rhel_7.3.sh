# ----------------------------------------------------------------------------
#
# Package	: leveldb
# Version	: 1.20
# Source repo	: https://github.com/google/leveldb
# Tested on	: rhel_7.3
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
sudo yum update -y
sudo yum install -y git gcc-c++ gcc wget make python yum-utils

# Clone and build code.
git clone https://github.com/google/leveldb
cd leveldb
make
sudo ldconfig
make check
