# ----------------------------------------------------------------------------
#
# Package       : Lodash
# Version       : 4.17.10
# Source repo   : https://github.com/lodash/lodash
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies
sudo apt-get -y update
sudo apt-get install -y curl git python-async node-lodash

# Install nodejs and npm
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash
source ~/.nvm/nvm.sh
nvm install stable
nvm use stable

# Download source
git clone https://github.com/lodash/lodash
cd lodash
git tag -l && git checkout 4.17.10

npm audit fix --force
npm clean cache
npm install 
npm test
