# ----------------------------------------------------------------------------
#
# Package	: loopback-connector
# Version	: 4.2.1
# Source repo	: https://github.com/strongloop/loopback-connector.git
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
sudo apt-get install -y wget git npm build-essential
WDIR=`pwd`

# Build and install node.
cd $WDIR
wget https://nodejs.org/dist/v4.2.3/node-v4.2.3.tar.gz
tar -xzf node-v4.2.3.tar.gz
cd node-v4.2.3
./configure
make
sudo make install

# Clone and build source code.
cd $WDIR
git clone https://github.com/strongloop/loopback-connector.git
cd loopback-connector
npm install
npm test
