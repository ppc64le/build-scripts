# ----------------------------------------------------------------------------
#
# Package       : spring-boot-configuration-processor
# Version       : 2.0.4.RELEASE
# Source repo   : http://central.maven.org/maven2/org/springframework/boot/spring-boot-configuration-processor/2.0.4.RELEASE/spring-boot-configuration-processor-2.0.4.RELEASE-sources.jar
# Tested on     : Ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Sandip Giri <sgiri@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install Dependencies
sudo apt-get update -y
sudo apt-get install -y wget openjdk-8-jdk ant maven

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# Download source-jar
cd $HOME
mkdir spring-boot-configuration-processor  && cd spring-boot-configuration-processor
wget http://central.maven.org/maven2/org/springframework/boot/spring-boot-configuration-processor/2.0.4.RELEASE/spring-boot-configuration-processor-2.0.4.RELEASE-sources.jar 
jar -xvf spring-boot-configuration-processor-2.0.4.RELEASE-sources.jar
wget http://central.maven.org/maven2/org/springframework/boot/spring-boot-configuration-processor/2.0.4.RELEASE/spring-boot-configuration-processor-2.0.4.RELEASE.pom
mv spring-boot-configuration-processor-2.0.4.RELEASE.pom pom.xml

# Build and Test
mvn clean install
mvn test
