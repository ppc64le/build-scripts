# ----------------------------------------------------------------------------
#
# Package       : PermissionsPlugin.js
# Version       : v1.0.7 
# Source repo   : https://github.com/GeKorm/webpack-permissions-plugin
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

# Default tag PermissionsPlugin.js
if [ -z "$1" ]; then
  export VERSION="v1.0.7"
else
  export VERSION="$1"
fi

# Variables
REPO=https://github.com/GeKorm/webpack-permissions-plugin

# install tools and dependent packages
yum update -y
yum install -y git  

# installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install v14.17.6

#Cloning Repo
git clone $REPO
cd webpack-permission-plugin
git checkout ${VERSION}

npm install -g yarn
yarn install
yarn add -D webpack-permissions-plugin