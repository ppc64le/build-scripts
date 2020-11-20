# ----------------------------------------------------------------------------
#
# Package       : react-tap-event-plugin
# Version       : 3.0.3
# Source repo   : https://github.com/zilverline/react-tap-event-plugin.git 
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


#Build and test react-tap-event-plugin
git clone  https://github.com/zilverline/react-tap-event-plugin.git 
cd react-tap-event-plugin/
npm install
npm test
