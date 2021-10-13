# ----------------------------------------------------------------------------
#
# Package       : log4j-slf4j-impl
# Version       : log4j-2.13.2
# Source repo   : https://github.com/apache/logging-log4j2
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
PACKAGE_URL=https://github.com/apache/logging-log4j2.git
PACKAGE_VERSION=log4j-2.13.2

echo "Usage: $0 [<PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional parameter whose default value is log4j-2.13.2, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

yum update -y 

#Install required files
yum install -y git maven

#Cloning Repo
git clone $PACKAGE_URL
cd logging-log4j2/log4j-slf4j-impl/
git checkout $PACKAGE_VERSION

#Build and test package
mvn install

echo "Complete!"
