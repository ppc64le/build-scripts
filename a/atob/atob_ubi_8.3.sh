#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : Atob
# Version       : v2.1.1, v2.1.2
# Source repo   : https://github.com/node-browser-compat/atob.git
# Tested on     : UBI: 8.3
# Language      : JavaScript
# Travis-Check  : True
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

# Variables
REPO=https://github.com/node-browser-compat/atob.git
PACKAGE_NAME=atob
PACKAGE_VERSION=${1:-v2.1.1}

# install tools and dependent packages
yum install -y git wget 

# install node
wget https://nodejs.org/dist/v16.4.2/node-v16.4.2-linux-ppc64le.tar.gz
tar -xzf node-v16.4.2-linux-ppc64le.tar.gz
export PATH=$CWD/node-v16.4.2-linux-ppc64le/bin:$PATH

#Cloning Repo
git clone $REPO
cd $PACKAGE_NAME
git checkout ${PACKAGE_VERSION}

sed -i '5 i "scripts": {"test": "node test.js"},' package.json

npm install 
npm audit fix 
npm test