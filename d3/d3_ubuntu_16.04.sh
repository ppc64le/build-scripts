# ----------------------------------------------------------------------------
#
# Package	: d3
# Version	: 4.12.0
# Source repo	: https://github.com/mbostock/d3.git
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
sudo apt-get install -y build-essential wget npm zip git
WDIR=`pwd`

# Build and install node.
wget https://nodejs.org/dist/v4.7.0/node-v4.7.0.tar.gz
tar -xzf node-v4.7.0.tar.gz
cd node-v4.7.0
./configure
make
sudo make install

# Clone and build d3.
cd $WDIR
git clone https://github.com/mbostock/d3.git
cd d3
npm install
npm test
