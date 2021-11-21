# ----------------------------------------------------------------------------
#
# Package       : netty-resolver
# Version       : netty-4.1.60.Final
# Source repo   : https://github.com/netty/netty
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
PACKAGE_URL=https://github.com/netty/netty.git
PACKAGE_VERSION=netty-4.1.60.Final

echo "Usage: $0 [<PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional parameter whose default value is netty-4.1.60.Final, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

yum update -y 

#Install required files
yum install -y git maven

#Cloning Repo
git clone $PACKAGE_URL
cd netty/resolver/ 
git checkout $PACKAGE_VERSION

#Build and test package
mvn install

echo "Complete!"