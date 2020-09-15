# ----------------------------------------------------------------------------
#
# Package	: react
# Version	: v16.2.0
# Source repo	: https://github.com/facebook/react
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
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
sudo yum update
sudo yum install -y wget 

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source $HOME/.nvm/nvm.sh
nvm install stable
nvm use stable

npm install yarn -g

#Build and test react
git clone https://github.com/facebook/react.git
cd react 
yarn install
yarn test
