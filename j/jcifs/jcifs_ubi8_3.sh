# ----------------------------------------------------------------------------
#
# Package       : jcifs
# Version       : master
# Source repo   : https://github.com/codelibs/jcifs
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
REPO=https://github.com/codelibs/jcifs 

# Install required files
yum update -y
yum install -y git maven java-1.8.0-openjdk-devel

#Clonning repo
git clone $REPO
cd jcifs/
git checkout master

#Build without tests
mvn install -DskipTests

#Run tests
mvn test