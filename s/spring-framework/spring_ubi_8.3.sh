#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : spring-framework
# Version       : v5.3.13
# Source repo   : https://github.com/spring-projects/spring-framework.git
# Tested on     : UBI 8.3
# Language      : Java, Others
# Ci-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : srividya chittiboina <Srividya.Chittiboina@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

REPO=https://github.com/spring-projects/spring-framework.git

# Default tag spring
if [ -z "$1" ]; then
  export VERSION="v5.3.13"
else
  export VERSION="$1"
fi

yum update -y
yum install wget git unzip -y
yum install  java-1.8.0-openjdk-devel maven -y

wget https://services.gradle.org/distributions/gradle-6.4.1-bin.zip -P /tmp
unzip -d /opt/gradle /tmp/gradle-*.zip
export GRADLE_HOME=/opt/gradle/gradle-6.4.1
export PATH=${GRADLE_HOME}/bin:${PATH}


#Cloning Repo
git clone $REPO
cd spring-framework
git checkout ${VERSION}

#Build repo
./gradlew build
#Test repo
./gradlew test
 


         
