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

yum update -y
yum install wget git unzip -y

yum install -y java-1.8.0-openjdk-devel
yum install -y maven
wget https://services.gradle.org/distributions/gradle-6.4.1-bin.zip -P /tmp
unzip -d /opt/gradle /tmp/gradle-*.zip
export GRADLE_HOME=/opt/gradle/gradle-6.4.1
export PATH=${GRADLE_HOME}/bin:${PATH}
git clone https://github.com/spring-projects/spring-framework.git
cd spring-framework
./gradlew build