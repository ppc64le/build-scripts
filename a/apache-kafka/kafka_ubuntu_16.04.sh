# ----------------------------------------------------------------------------
#
# Package       : kafka
# Version       : 1.1.0
# Source repo   : https://github.com/apache/kafka
# Tested on     : Ubuntu_16.04
# Language      : Java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
#Install dependencies
sudo apt-get update -y
sudo apt-get install -y git openjdk-8-jdk wget unzip

cd /tmp
wget https://services.gradle.org/distributions/gradle-4.8-bin.zip
unzip gradle-4.8-bin.zip

#Set required environment variables
export PATH=/tmp/gradle-4.8/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export JRE_HOME=${JAVA_HOME}/jre
export PATH=$PATH:${JAVA_HOME}/bin:$PATH

#Build and run unit tests
cd $HOME
git clone https://github.com/apache/kafka
cd kafka
git checkout 1.1.0

gradle clean
gradle
./gradlew jar
./gradlew releaseTarGz -x signArchives
./gradlew unitTest
