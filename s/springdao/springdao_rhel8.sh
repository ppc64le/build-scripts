# ----------------------------------------------------------------------------
#
# Package       : springDao
# Version       : v5.3.10
# Source repo   : https://github.com/spring-projects/spring-framework.git
# Tested on     : RHEL8
# Script License: Apache License, Version 2 or later
# Maintainer    : Narasimha udala<narasimha.rao.udala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
export REPO=https://github.com/spring-projects/spring-framework.git

#Default tag Generex
if [ -z "$1" ]; then
  export VERSION="v5.3.10"
else
  export VERSION="$1"
fi

yum update -y
yum install wget git unzip -y

yum install -y java-1.8.0-openjdk-devel
yum install -y maven
wget https://services.gradle.org/distributions/gradle-6.4.1-bin.zip -P /tmp
unzip -d /opt/gradle /tmp/gradle-*.zip
export GRADLE_HOME=/opt/gradle/gradle-6.4.1
export PATH=${GRADLE_HOME}/bin:${PATH}
git clone ${REPO}
cd spring-framework
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi
./gradlew build
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done  Build and Test ......"
else
  echo  "Failed Test ......"
fi