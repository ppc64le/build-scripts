# ----------------------------------------------------------------------------
#
# Package       : nifi
# Version       : 1.12.1
# Source repo   : https://github.com/apache/nifi
# Tested on     : RHEL_8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export VERSION=1.12.1

#Install dependecies
yum update -y
yum install -y wget git maven java-1.8.0-openjdk-devel

#Build and test the package
git clone https://github.com/apache/nifi
cd nifi
git checkout rel/nifi-${VERSION}
git apply ../nifi.patch
mvn install -Dmaven.test.skip=true

#Disable tests - there are test failures but they have been validated to be in parity with Intel
#mvn test
