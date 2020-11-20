# ----------------------------------------------------------------------------
#
# Package       : Eclipse Runtime
# Version       : 3.6.0
# Source repo   : http://repository.mulesoft.org/releases/org/eclipse/eclipse-runtime/3.6.0.v20100505/eclipse-runtime-3.6.0.v20100505.jar
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
mkdir eclipse_runtime && cd eclipse_runtime
wget http://repository.mulesoft.org/releases/org/eclipse/eclipse-runtime/3.6.0.v20100505/eclipse-runtime-3.6.0.v20100505.jar
jar -xvf eclipse-runtime-3.6.0.v20100505.jar
wget  http://repository.mulesoft.org/releases/org/eclipse/eclipse-runtime/3.6.0.v20100505/eclipse-runtime-3.6.0.v20100505.pom
mv eclipse-runtime-3.6.0.v20100505.pom pom.xml

# Build and Test
mvn clean install
mvn test
