# ----------------------------------------------------------------------------
#
# Package       : Glob
# Version       : v7.1.6, v7.1.7, v5.0.15, v7.1.4, v3.2.11
# Source repo   : https://github.com/isaacs/node-glob 
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Default tag for Glob
if [ -z "$1" ]; then
  export VERSION="v7.1.7"
else
  export VERSION="$1"
fi

# Variables
REPO=https://github.com/isaacs/node-glob 

# install tools and dependent packages
yum update -y
yum install -y git 

# install node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install v12.22.4

#Cloning Repo
git clone $REPO
cd node-glob
git checkout ${VERSION}

npm install yarn -g
yarn install
yarn test
#Observed 10 test failures for the version 3.2.11, which are in parity with Intel.