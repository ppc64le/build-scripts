#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : bcpkix-jdk15on
# Version       : r1rv61,r1rv65,r1rv70
# Source repo   : https://github.com/bcgit/bc-java
# Tested on     : UBI: 8.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Srividya Chittiboina <Srividya.Chittiboina@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

REPO=https://github.com/bcgit/bc-java

# Default tag for bcpkix-jdk15on

VERSION=${1:-r1rv70}

yum install -y git wget unzip
yum install -y java-1.8.0-openjdk-devel

# install gradle
if "$VERSION"=r1rv61
then 
  GRADLE_VERSION=4.0.1
else
  GRADLE_VERSION=5.1.1
fi

wget https://downloads.gradle-dn.com/distributions/gradle-$GRADLE_VERSION-all.zip
unzip -d /opt/gradle gradle-$GRADLE_VERSION-all.zip
ls /opt/gradle/gradle-$GRADLE_VERSION/
export PATH=$PATH:/opt/gradle/gradle-$GRADLE_VERSION/bin

# Cloning Repo
git clone $REPO
cd bc-java
git checkout ${VERSION}
cd pkix

export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"

# Build package
gradle build -x test
# Test Package
# For version r1rv61 test failed as below which is in parity with intel
#704 tests completed, 3 failed
#
gradle test 

