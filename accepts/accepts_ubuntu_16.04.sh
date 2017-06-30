# ----------------------------------------------------------------------------
#
# Package	: accepts
# Version	: 1.3.3
# Source repo	: https://github.com/jshttp/accepts.git
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
sudo apt-get install -y build-essential npm wget git

WDIR=`pwd`
# Build and install node.
cd $WDIR
wget https://nodejs.org/dist/v4.2.3/node-v4.2.3.tar.gz
tar -xzf node-v4.2.3.tar.gz
cd node-v4.2.3
./configure
make
sudo make install

cd $WDIR
git clone https://github.com/jshttp/accepts.git accepts
cd accepts
npm install
npm test
