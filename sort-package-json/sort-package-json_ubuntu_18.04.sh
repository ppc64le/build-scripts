# ----------------------------------------------------------------------------
#
# Package       : sort-package-json
# Version       : 1.7.0 
# Source repo   : https://github.com/keithamus/sort-package-json.git
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


#Build and test sort-package-json
git clone https://github.com/keithamus/sort-package-json.git
cd sort-package-json/
npm install
npm audit fix
npm test
