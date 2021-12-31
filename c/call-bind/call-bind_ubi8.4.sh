# ----------------------------------------------------------------------------
#
# Package       : call-bind
# Version       : master(a994df69f401f4bf735a4ccd77029b85d1549453)
# Source repo   : https://github.com/ljharb/call-bind.git
# Tested on     : UBI 8.4
# Script License: MIT License
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
PACKAGE_URL=https://github.com/ljharb/call-bind.git
PACKAGE=call-bind
#Test fails for required version and latest stable version
PACKAGE_VERSION=a994df69f401f4bf735a4ccd77029b85d1549453
NODE_VERSION=v12.22.8
DISTRO=linux-ppc64le

yum update -y 

#Install dev dependencies 
yum install -y git wget gcc gcc-c++ python2 make

#Installing node
PATH=/node-$NODE_VERSION-$DISTRO/bin:$PATH
wget https://nodejs.org/dist/latest-v12.x/node-$NODE_VERSION-$DISTRO.tar.gz
tar -C / -xzf node-$NODE_VERSION-$DISTRO.tar.gz

#Cloning Repo
git clone $PACKAGE_URL
cd $PACKAGE
git checkout $PACKAGE_VERSION

#Build package
npm install
npm i --package-lock-only
npm audit fix --force

#Test pacakge
npm test