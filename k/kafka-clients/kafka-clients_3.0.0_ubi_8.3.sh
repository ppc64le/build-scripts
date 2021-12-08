# ---------------------------------------------------------------------
#
# Package       : kafka-clients
# Version       : 3.0.0
# Source repo   : https://github.com/apache/kafka
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

#!/bin/bash

#Variables
REPO=https://github.com/apache/kafka
PACKAGE_VERSION=3.0.0

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 3.0.0, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Install required packages
yum install -y git wget unzip java-1.8.0-openjdk java-1.8.0-openjdk-devel

#Clone and checkout the package
cd /opt
git clone $REPO
cd kafka/
git checkout $PACKAGE_VERSION

#Build and test package
./gradlew clients:jar
./gradlew clients:unitTest

echo "Complete!"
