# ----------------------------------------------------------------------------
#
# Package       : micrometer-core
# Version       : master
# Source repo   : https://github.com/micrometer-metrics/micrometer
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
PACKAGE_URL=https://github.com/micrometer-metrics/micrometer.git

yum update -y 

#Install required files
yum install -y git 

#Cloning Repo
git clone $PACKAGE_URL
cd micrometer/
git checkout

#Build test package
./gradlew build
./gradlew test

echo "Complete!"