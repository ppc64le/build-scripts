#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : js-xss
# Version       : v1.0.14
# Source repo   : https://github.com/leizongmin/js-xss
# Tested on     : UBI 8
# Language      : HTML, Javascript
# Travis-Check  : True
# Script License: Apache-2.0 License
# Maintainer    : Vaibhav Nazare <vaibhav_nazare@persistent.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=js-xss
PACKAGE_VERSION=${1:-v1.0.14}
PACKAGE_URL=https://github.com/leizongmin/js-xss.git

#Install Required Files
yum -y update
yum install -y git wget 
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz"
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz
export PATH=$PWD/node-v12.22.4-linux-ppc64le/bin:$PATH

#Cloning repo
git clone $PACKAGE_URL
cd js-xss/
git checkout $PACKAGE_VERSION

npm install
npm audit fix --force
npm run test
