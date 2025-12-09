#!/bin/bash -e   
# ----------------------------------------------------------------------------
#
# Package       : jackson-module-scala 
# Version       : v2.17.2
# Source repo   : https://github.com/FasterXML/jackson-module-scala 
# Tested on     : UBI: 9.3
# Language      : Scala,Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : kotla santhosh<kotla.santhosh@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=jackson-module-scala
PACKAGE_URL=https://github.com/FasterXML/jackson-module-scala.git
PACKAGE_VERSION=${1:-v2.17.2}


# install tools and dependent packages
yum install -y git wget unzip java-21-openjdk-devel 
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Install sbt
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum install -y sbt

# Cloning the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
sbt compile 
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
  
 
#Test
sbt test
if [ $? != 0 ]
then
  echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 2
fi
exit 0

