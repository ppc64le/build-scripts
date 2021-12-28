#----------------------------------------------------------------------------
#
# Package         : mobxjs/mobx
# Version         : mobx@6.3.3
# Source repo     : https://github.com/mobxjs/mobx.git
# Tested on       : ubi:8.3
# Script License  : MIT License
# Maintainer      : srividya chittiboina <Srividya.Chittiboina@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
#
# ----------------------------------------------------------------------------

REPO=https://github.com/mobxjs/mobx.git

# Default tag mobx
if [ -z "$1" ]; then
  export VERSION="mobx@6.3.3"
else
  export VERSION="$1"
fi

dnf install -y git autoconf automake libtool make wget

#Install Nodejs version 16 
wget https://nodejs.org/dist/v16.4.2/node-v16.4.2-linux-ppc64le.tar.gz
tar -xzf node-v16.4.2-linux-ppc64le.tar.gz
export PATH=$CWD/node-v16.4.2-linux-ppc64le/bin:$PATH

#Cloning Repo
git clone $REPO
cd  mobx
#Install yarn package
npm install yarn -g
npm install -g npm@7.24.0
#Checkout to the version
git checkout ${VERSION}

#Build repo
yarn -y install

#Test repo
chmod +r packages/mobx-undecorate/__tests__/fixtures
yarn lerna run build:test
yarn test


         