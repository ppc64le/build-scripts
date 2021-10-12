# ----------------------------------------------------------------------------
#
# Package       : netty-codec-http2
# Version       : netty-4.1.48.Final
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
PACKAGE_VERSION=netty-4.1.48.Final

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is netty-4.1.48.Final, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

yum update -y 

#Install required files
yum install -y git maven

#Cloning Repo
git clone $PACKAGE_URL
cd netty/codec-http2/
git checkout $PACKAGE_VERSION

#Build package
mvn clean install

#Test pacakge
mvn test 

echo "Complete!"
