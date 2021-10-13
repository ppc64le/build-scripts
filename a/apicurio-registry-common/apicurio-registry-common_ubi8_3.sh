# ----------------------------------------------------------------------------
#
# Package       : apicurio-registry-common
# Version       : 1.3.0.Final
# Source repo   : https://github.com/apicurio/apicurio-registry
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
PACKAGE_URL=https://github.com/Apicurio/apicurio-registry.git
PACKAGE_VERSION=1.3.0.Final

echo "Usage: $0 [<PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional parameter whose default value is 1.3.0.Final, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

yum update -y 

#Install required files
yum install -y git maven 

#Cloning Repo
git clone $PACKAGE_URL
cd apicurio-registry/common/
git checkout $PACKAGE_VERSION

#Build and test package
mvn install

echo "Complete!"