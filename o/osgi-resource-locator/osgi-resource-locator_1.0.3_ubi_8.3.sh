# ---------------------------------------------------------------------
#
# Package       : osgi-resource-locator
# Version       : 1.0.3
# Source repo   : https://github.com/eclipse-ee4j/glassfish-hk2-extra.git
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/sh

#Variables
REPO=https://github.com/eclipse-ee4j/glassfish-hk2-extra.git
PACKAGE_VERSION=1.0.3

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 1.0.3"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Install Dependencies
yum install -y java-1.8.0-openjdk-devel git maven

#Clone the repo
cd /opt/
git clone $REPO
cd glassfish-hk2-extra

#Checkout the required version
git checkout ${PACKAGE_VERSION}-RELEASE
cd osgi-resource-locator/

#Build and test
mvn verify -Dgpg.skip
mvn test

#Done
echo "/opt/glassfish-hk2-extra/osgi-resource-locator/target/osgi-resource-locator-${PACKAGE_VERSION}.jar"
echo "/opt/glassfish-hk2-extra/osgi-resource-locator/target/osgi-resource-locator-${PACKAGE_VERSION}-javadoc.jar"
echo "Complete!"
