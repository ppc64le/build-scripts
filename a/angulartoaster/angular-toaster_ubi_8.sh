# ----------------------------------------------------------------------------
#
# Package       : angular-translate
# Version       : 2.18.1
# Source repo   : https://github.com/angular-translate/angular-translate
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
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
sudo apt-get install -y git nodejs npm phantomjs curl
sudo npm install -g bower

#Install nvm
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash

source ~/.nvm/nvm.sh
if [ $? -ne 0 ]
then
        echo "FAILED to install required NPM version - re-run script with bash"
        exit
fi
nvm install stable
nvm use stable

#Set environment variables
export QT_QPA_PLATFORM=offscreen

# Clone and build source.
git clone https://github.com/angular-translate/angular-translate
cd angular-translate
npm install
#Disabling test execution as karma:unit tests are failing due to un-availibilty
#of headless chrome in Power, these are not expected to have any functional impact
#npm test
