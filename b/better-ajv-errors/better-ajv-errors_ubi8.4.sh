# ----------------------------------------------------------------------------
#
# Package       : better-ajv-errors
# Version       : v0.5.7
# Source repo   : https://github.com/atlassian/better-ajv-errors.git
# Tested on     : UBI 8.4
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Mahima Gaikwad <mahima.gaikwad@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -e

#Variables
PACKAGE_NAME=better-ajv-errors
PACKAGE_VERSION=${1:-v0.5.7}
PACKAGE_URL=https://github.com/atlassian/better-ajv-errors.git

NODE_VERSION=v12.22.9
DISTRO=linux-ppc64le

#Install dev dependencies 
yum install -y git wget

#Installing node
PATH=/node-$NODE_VERSION-$DISTRO/bin:$PATH
wget https://nodejs.org/dist/latest-v12.x/node-$NODE_VERSION-$DISTRO.tar.gz
tar -C / -xzf node-$NODE_VERSION-$DISTRO.tar.gz

#Cloning Repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build package
npm install
npm audit fix --force

#Test pacakge
npm test -- -u