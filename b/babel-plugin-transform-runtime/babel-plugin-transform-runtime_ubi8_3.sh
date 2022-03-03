# ----------------------------------------------------------------------------
#
# Package       : babel-plugin-transform-runtime
# Version       : v7.4.0
# Language      : JavaScript 
# Source repo   : https://github.com/babel/babel
# Tested on     : UBI 8.3
# Script License: Apache-2.0 License    
# Maintainer    : Varsha Aaynure <Varsha.Aaynure@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Variables
PACKAGE_URL=https://github.com/babel/babel.git
PACKAGE_VERSION="${1:-v7.4.0}"

#Install required files
yum install -y git wget

#To install node 12 
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz"
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz
export PATH=node-v12.22.4-linux-ppc64le/bin:$PATH

#Cloning Repo
git clone $PACKAGE_URL
cd babel/packages/babel-plugin-transform-runtime/
git checkout $PACKAGE_VERSION

#Build package
npm install

#Test package 
npm test       # No test files found for this 

echo "Complete!"