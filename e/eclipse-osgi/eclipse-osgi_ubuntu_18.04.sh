# ----------------------------------------------------------------------------
#
# Package       : Eclipse OSGI
# Version       : 3.7.1
# Source repo   : http://central.maven.org/maven2/org/eclipse/osgi/org.eclipse.osgi/3.7.1/org.eclipse.osgi-3.7.1.jar
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
mkdir eclipse_osgi && cd eclipse_osgi
wget http://central.maven.org/maven2/org/eclipse/osgi/org.eclipse.osgi/3.7.1/org.eclipse.osgi-3.7.1.jar
jar -xvf org.eclipse.osgi-3.7.1.jar
wget http://central.maven.org/maven2/org/eclipse/osgi/org.eclipse.osgi/3.7.1/org.eclipse.osgi-3.7.1.pom
mv org.eclipse.osgi-3.7.1.pom pom.xml

# Build and Test
mvn clean install
mvn test
