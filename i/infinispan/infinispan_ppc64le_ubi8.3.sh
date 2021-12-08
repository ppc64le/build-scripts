# ----------------------------------------------------------------------------
#
# Package       : infinispan
# Version       : 12.1.3.Final
# Source repo   : https://github.com/infinispan/infinispan
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

BUILD_VERSION=12.1.3.Final

#Install dependencies
yum -y update
yum -y install wget git
yum install -y openssl-devel.ppc64le
yum install -y java-1.8.0-openjdk-devel.ppc64le 
yum install -y maven

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

#Build Infinispan
git clone https://github.com/infinispan/infinispan
cd infinispan && git checkout $BUILD_VERSION
mvn -s maven-settings.xml clean install -DskipTests=true
