# ----------------------------------------------------------------------------
#
# Package       : OSGi Service CM
# Version       : r8-core-final-rerelease
# Source repo   : https://github.com/osgi/osgi
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Vaibhav Nazare <Vaibhav.Nazare@ibm.com>
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
REPO=https://github.com/osgi/osgi.git
PACKAGE_VERSION=r8-core-final-rerelease   


echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is r8-core-final-rerelease"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Install required files
yum update -y
yum install -y git java-1.8.0-openjdk-devel

#Cloning Repo
git clone $REPO
cd osgi/
git checkout $PACKAGE_VERSION

#Build and test package
./gradlew :build
./gradlew :osgi.specs:specifications
./gradlew :org.osgi.test.cases.remoteserviceadmin:testOSGi