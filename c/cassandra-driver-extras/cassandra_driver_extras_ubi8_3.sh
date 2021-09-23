# ----------------------------------------------------------------------------
#
# Package       : cassandra-driver-extras
# Version       : 4.12.0
# Source repo   : https://github.com/datastax/java-driver
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
REPO=https://github.com/datastax/java-driver.git
PACKAGE_VERSION=4.12.0


echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 4.12.0"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"


# Install required files
yum update -y
yum install -y git maven java-1.8.0-openjdk-devel

#Clonning repo
git clone $REPO
cd java-driver/
git checkout $PACKAGE_VERSION

#Build without tests
mvn clean package -DskipTests

#Run tests
mvn test