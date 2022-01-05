# ----------------------------------------------------------------------------
#
# Package       : ua-parser-js
# Version       : master
# Source repo   : https://github.com/faisalman/ua-parser-js
# Tested on     : UBI 8
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

#!/bin/bash
REPO=https://github.com/faisalman/ua-parser-js.git
PACKAGE_VERSION=master

#Install Required Files
yum -y update
yum install -y git wget 
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz"
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz
export PATH=$CWD/node-v12.22.4-linux-ppc64le/bin:$PATH

#Cloning repo
git clone $REPO
cd ua-parser-js/
git checkout $PACKAGE_VERSION

npm install
npm i --package-lock-only
npm audit fix --force
npm run test
