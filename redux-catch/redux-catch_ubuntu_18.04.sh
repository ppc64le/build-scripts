# ----------------------------------------------------------------------------
#
# Package       : redux-catch
# Version       : 1.3.1
# Source repo   : https://github.com/PlatziDev/redux-catch.git 
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install dependencies
sudo apt-get update
sudo apt-get install -y wget git

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source $HOME/.nvm/nvm.sh
nvm install stable
nvm use stable


#Build and test redux-catch
git clone   https://github.com/PlatziDev/redux-catch.git 
cd redux-catch/
npm install
npm test
