# ----------------------------------------------------------------------------
#
# Package	: bloom
# Version	: Not available.
# Source repo	: https://github.com/ArashPartow/bloom
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
sudo yum update -y
sudo yum install -y make gcc gcc-c++ git

# Clone and build bloom.
git clone https://github.com/arashpartow/bloom
cd bloom
make

# Execute test examples.
./bloom_filter_example01
./bloom_filter_example02
./bloom_filter_example03
