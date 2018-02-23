# ----------------------------------------------------------------------------
#
# Package       : JSDoc
# Version       : 3.5.5
# Source repo   : https://github.com/jsdoc3/jsdoc.git
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum -y update
sudo yum -y install wget git
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source $HOME/.nvm/nvm.sh
vm install stable
nvm use stable

git clone https://github.com/jsdoc3/jsdoc.git
cd jsdoc
npm install -g gulp
npm install
./jsdoc.js -T
