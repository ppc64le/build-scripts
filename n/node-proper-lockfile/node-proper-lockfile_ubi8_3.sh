# ----------------------------------------------------------------------------
#
# Package       : node-proper-lockfile
# Version       : v4.1.1
# Source repo   : https://github.com/moxystudio/node-proper-lockfile
# Tested on     : UBI 8.3
# Script License: MIT License
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
PACKAGE_URL=https://github.com/moxystudio/node-proper-lockfile.git
PACKAGE_VERSION=v4.1.1
NODE_VERSION=v12.22.4

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is v4.1.1, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

yum update -y 

#Install required files
yum install -y git

#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

#Cloning Repo
git clone $PACKAGE_URL
cd node-proper-lockfile/
git checkout $PACKAGE_VERSION

#Build package
npm i
npm audit fix
npm audit fix --force
npm install
npm audit fix
npm audit fix --force
npm i

#Test pacakge
npm test 

echo "Complete!"
