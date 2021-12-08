# ----------------------------------------------------------------------------
#
# Package       : picocli
# Version       : 4.6.1
# Source repo   : https://github.com/remkop/picocli
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
REPO=https://github.com/remkop/picocli.git
PACKAGE_VERSION=v4.6.1

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is v4.6.1"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"



#Install required files
yum update -y
yum install -y git java-1.8.0-openjdk-devel

#Cloning Repo
git clone $REPO
cd picocli/
git checkout $PACKAGE_VERSION

#Build and test package
./gradlew build