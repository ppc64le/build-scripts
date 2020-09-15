# ----------------------------------------------------------------------------
#
# Package       : spring-boot-starter-actuator
# Version       : 2.0.4.RELEASE
# Source repo   : http://central.maven.org/maven2/org/springframework/boot/spring-boot-starter-actuator/2.0.4.RELEASE/spring-boot-starter-actuator-2.0.4.RELEASE.jar
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
mkdir spring-boot-starter-actuator  && cd spring-boot-starter-actuator
wget http://central.maven.org/maven2/org/springframework/boot/spring-boot-starter-actuator/2.0.4.RELEASE/spring-boot-starter-actuator-2.0.4.RELEASE.jar 
jar -xvf spring-boot-starter-actuator-2.0.4.RELEASE.jar
wget http://central.maven.org/maven2/org/springframework/boot/spring-boot-starter-actuator/2.0.4.RELEASE/spring-boot-starter-actuator-2.0.4.RELEASE.pom
mv spring-boot-starter-actuator-2.0.4.RELEASE.pom pom.xml

# Build and Test
mvn clean install
mvn test
