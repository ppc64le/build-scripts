# ----------------------------------------------------------------------------
#
# Package	: mongo-c-driver
# Version	: 1.6.0
# Source repo	: https://github.com/mongodb/mongo-c-driver.git
# Tested on	: rhel_7.2
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
sudo yum install -y git automake autoconf libtool which make cyrus-sasl-devel

# Download source and build the driver.
git clone https://github.com/mongodb/mongo-c-driver.git
cd mongo-c-driver
./autogen.sh --with-libbson=bundled
make && sudo make install
