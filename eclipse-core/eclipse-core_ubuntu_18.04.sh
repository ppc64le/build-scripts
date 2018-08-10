# ----------------------------------------------------------------------------
#
# Package       : Eclipse-core
# Version       : 3.6.0
# Source repo   : https://mvnrepository.com/artifact/org.eclipse.core/org.eclipse.core.commands
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
mkdir eclipse_core && cd eclipse_core
wget http://central.maven.org/maven2/org/eclipse/core/org.eclipse.core.commands/3.6.0/org.eclipse.core.commands-3.6.0-sources.jar 
jar -xvf org.eclipse.core.commands-3.6.0-sources.jar
wget http://central.maven.org/maven2/org/eclipse/core/org.eclipse.core.commands/3.6.0/org.eclipse.core.commands-3.6.0.pom
mv org.eclipse.core.commands-3.6.0.pom pom.xml

# Build and Test
mvn clean install
mvn test
