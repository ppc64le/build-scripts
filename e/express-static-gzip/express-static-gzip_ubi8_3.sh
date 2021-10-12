# ----------------------------------------------------------------------------
#
# Package       : express-static-gzip
# Version       : v0.3.2
# Source repo   : https://github.com/tkoenig89/express-static-gzip
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
PACKAGE_VERSION=v0.3.2
NODE_VERSION=v12.22.4
PACKAGE_URL=https://github.com/tkoenig89/express-static-gzip.git

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is v0.3.2, not all versions are supported."

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
cd express-static-gzip/
git checkout $PACKAGE_VERSION

#Build package
npm i

#Test pacakge
npm test 
# No test files found for this version

echo "Complete!"


