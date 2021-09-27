#----------------------------------------------------------------------------
#
# Package         : styled-components/polished
# Version         : v4.1.3
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
#Tested versions: v2.3.3,v3.7.0,v4.1.3
# ----------------------------------------------------------------------------

REPO=https://github.com/styled-components/polished.git

# Default tag polished
if [ -z "$1" ]; then
  export VERSION="v4.1.3"
else
  export VERSION="$1"
fi

yum install git wget -y

#Install Nodejs version 16 
wget https://nodejs.org/download/release/latest-v14.x/node-v14.17.6-linux-ppc64le.tar.gz
tar -xzf node-v14.17.6-linux-ppc64le.tar.gz
export PATH=$CWD/node-v14.17.6-linux-ppc64le/bin:$PATH

#Cloning Repo
git clone $REPO
cd  polished
#Install yarn package
npm install yarn -g

#Checkout to the version
git checkout ${VERSION}

#Build repo
yarn  install

#Test repo
yarn test


         