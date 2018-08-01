# ----------------------------------------------------------------------------
#
# Package       : babel
# Version       : v7.0.0-beta.55
# Source repo   : https://github.com/babel/babel.git
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth<sethp@us.ibm.com>
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
sudo apt-get install -y curl make build-essential git

export NVM_DIR=$HOME/.nvm
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash
source ~/.nvm/nvm.sh
if [ $? -ne 0 ]
then
        echo "FAILED to install required NPM version - re-run script with bash"
        exit
fi
nvm install stable
nvm use stable

git clone --depth=10 https://github.com/babel/babel.git babel/babel
cd babel/babel
sudo npm install -g yarn
make
make bootstrap
make test
