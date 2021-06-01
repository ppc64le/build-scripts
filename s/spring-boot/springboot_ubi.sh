# ----------------------------------------------------------------------------
#
# Package       : spring-boot
# Version       : 2.5.0
# Source repo   : https://github.com/spring-projects/spring-boot
# Tested on     : ubi8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Md.Afsan Hossain <mdafsan.hossain@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
VERSION=v2.5.0

#Install dependencies
yum update -y
yum install git -y
yum install java-1.8.0-openjdk-devel.ppc64le -y

#export variables
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk


#Build Spring boot
git clone https://github.com/spring-projects/spring-boot
cd spring-boot
git checkout $VERSION
./gradlew build
