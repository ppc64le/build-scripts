# ----------------------------------------------------------------------------
#
# Package       : picocli
# Version       : v4.5.2 
# Language      : Java
# Source repo   : https://github.com/remkop/picocli
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
PACKAGE_URL=https://github.com/remkop/picocli.git
PACKAGE_VERSION="${1:-v4.5.2}"

#Install required files
yum install -y git java-1.8.0-openjdk-devel

#Cloning Repo
git clone $PACKAGE_URL
cd picocli/
git checkout $PACKAGE_VERSION

#Build and test package
./gradlew build

echo "Complete!"