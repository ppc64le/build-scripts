#!/bin/bash -e
#----------------------------------------------------------------------------
#
# Package         : xtuc/webassemblyjs
# Version         : v1.7.10
# Source repo     : https://github.com/xtuc/webassemblyjs
# Tested on       : ubi:8.3
# Language        : JavaScript
# Travis-Check    : true
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
#Tested versions: v1.11.1,v1.7.10.v1.7.11
# ----------------------------------------------------------------------------

REPO=https://github.com/xtuc/webassemblyjs.git

# Default tag Webassemblyjs
if [ -z "$1" ]; then
  export VERSION="v1.7.10"
else
  export VERSION="$1"
fi

dnf install git  wget make  gcc -y

#Install Nodejs version 12 or above 
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz"
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz
export PATH=$CWD/node-v12.22.4-linux-ppc64le/bin:$PATH

#Cloning Repo
git clone $REPO
cd  webassemblyjs
#Install yarn package
npm install yarn -g
git checkout ${VERSION}

#build repo
yarn install
#test repo
yarn test


         
