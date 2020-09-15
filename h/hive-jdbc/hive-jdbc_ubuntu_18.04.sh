# ----------------------------------------------------------------------------
#
# Package       : hive-jdbc
# Version       : 3.1.0
# Source repo   : http://central.maven.org/maven2/org/apache/hive/hive-jdbc/3.1.0/hive-jdbc-3.1.0-sources.jar
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
mkdir hive-jdbc && cd hive-jdbc
wget http://central.maven.org/maven2/org/apache/hive/hive-jdbc/3.1.0/hive-jdbc-3.1.0-sources.jar
jar -xvf hive-jdbc-3.1.0-sources.jar
wget http://central.maven.org/maven2/org/apache/hive/hive-jdbc/3.1.0/hive-jdbc-3.1.0.pom 
mv hive-jdbc-3.1.0.pom pom.xml

# Build and Test
mkdir -p ../data/conf
mvn clean install
mvn test
