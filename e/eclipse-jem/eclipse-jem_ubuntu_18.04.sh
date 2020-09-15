# ----------------------------------------------------------------------------
#
# Package       : Eclipse Jem
# Version       : 2.0.0
# Source repo   : https://mvnrepository.com/artifact/org.wso2.wsf/org.eclipse.jem/2.0.0
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
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
mkdir eclipse_jem && cd eclipse_jem
wget http://dist.wso2.org/maven2/org/wso2/wsf/org.eclipse.jem/2.0.0/org.eclipse.jem-2.0.0.jar
jar -xvf org.eclipse.jem-2.0.0.jar
wget  http://dist.wso2.org/maven2/org/wso2/wsf/org.eclipse.jem/2.0.0/org.eclipse.jem-2.0.0.pom
mv  org.eclipse.jem-2.0.0.pom pom.xml

# Build and Test
mvn clean install
mvn test
