# ----------------------------------------------------------------------------
#
# Package       : jotted
# Version       : master
# Source repo   : https://github.com/ghinda/jotted.git
# Tested on     : ubuntu_16.04
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

WDIR=`pwd`
sudo apt-get update -y
sudo apt-get install -y npm git wget nodejs
#install npm 
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh| sh
source ~/.nvm/nvm.sh
nvm install stable
nvm use stable

export PATH=./node_modules/.bin:$PATH
export SAUCE_USERNAME=[secure]
export SAUCE_ACCESS_KEY=[secure]

cd $WDIR
git clone https://github.com/ghinda/jotted.git
cd $WDIR/jotted
npm install
npm test 
