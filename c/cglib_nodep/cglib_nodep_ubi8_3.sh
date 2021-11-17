# ----------------------------------------------------------------------------
#
# Package       : CGLib-nodep
# Version       : RELEASE_3_3_0, RELEASE_3_2_9 
# Source repo   : https://github.com/cglib/cglib
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Vaibhav Nazare <Vaibhav.Nazare@ibm.com>
#
# Disclaimer: This script has beentested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

#Variables
REPO=https://github.com/cglib/cglib.git
PACKAGE_VERSION=RELEASE_3_3_0 


echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is RELEASE_3_3_0"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"


# Install required files
yum update -y
yum install -y git maven java-1.8.0-openjdk-devel

#Clonning repo
git clone $REPO
cd cglib/
git checkout $PACKAGE_VERSION

#Build without tests
mvn clean package -DskipTests

#Run tests
mvn test