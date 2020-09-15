# ----------------------------------------------------------------------------
#
# Package	: axon
# Version	: 2.0.3
# Source repo	: https://github.com/tj/axon
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
sudo apt-get install -y git npm build-essential wget

WORKDIR=$HOME

# Build and install node.
cd $WORKDIR
wget https://nodejs.org/dist/v4.2.3/node-v4.2.3.tar.gz
tar -xzf node-v4.2.3.tar.gz
cd node-v4.2.3 && ./configure && make && sudo make install

# Build and test axon.
cd $WORKDIR
git clone https://github.com/tj/axon
cd axon
npm install
npm test
