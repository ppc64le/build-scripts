# ----------------------------------------------------------------------------
#
# Package	: Eslint
# Version	: 4.16.0
# Source repo	: https://github.com/eslint/eslint 
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update
sudo apt-get install git wget bzip2 libfontconfig1 -y 
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source ~/.nvm/nvm.sh
nvm install stable
nvm use stable
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2 
sudo mv phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin
rm -rf phantomjs-2.1.1-linux-ppc64.tar.bz2

cd $HOME
git clone https://github.com/eslint/eslint.git
cd eslint
npm install
npm test
