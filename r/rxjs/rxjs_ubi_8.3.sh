# ----------------------------------------------------------------------------
#
# Package       : rxjs
# Version       : 7.3.0
# Source repo   : https://github.com/ReactiveX/rxjs
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

# Default tag rxjs
if [ -z "$1" ]; then
  export VERSION="7.3.0"
else
  export VERSION="$1"
fi

# Variables
REPO=https://github.com/ReactiveX/rxjs
NODE_VERSION=v14.17.6

# install tools and dependent packages
yum update -y
yum install -y git curl 

#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

#Cloning Repo
git clone $REPO
cd /rxjs
git checkout ${VERSION}

npm install -g yarn
yarn install
yarn test