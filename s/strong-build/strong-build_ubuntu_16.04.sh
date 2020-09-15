# ----------------------------------------------------------------------------
#
# Package	: strong-build
# Version	: 2.1.2
# Source repo	: https://github.com/strongloop/strong-build.git
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

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y build-essential npm wget git
WDIR=`pwd`

# Build and install node.
cd $WDIR
wget https://nodejs.org/dist/v4.7.0/node-v4.7.0.tar.gz
tar -xzf node-v4.7.0.tar.gz
cd node-v4.7.0
./configure
make
sudo make install

# Clone and build source code.
cd $WDIR
git clone https://github.com/strongloop/strong-build.git
cd strong-build
git config --global user.email "sethp@us.ibm.com"
git config --global user.name "Priya Seth"
npm install && npm test
