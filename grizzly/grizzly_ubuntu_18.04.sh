# ----------------------------------------------------------------------------
#
# Package       : Grizzly
# Version       : 1.0.28
# Source repo   : https://search.maven.org/remotecontent?filepath=grizzly/grizzly/1.0.28/grizzly-1.0.28-sources.jar
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
cd $HOME
mkdir grizzly && cd grizzly
wget https://search.maven.org/remotecontent?filepath=grizzly/grizzly/1.0.28/grizzly-1.0.28-sources.jar
jar -xvf remotecontent?filepath=grizzly%2Fgrizzly%2F1.0.28%2Fgrizzly-1.0.28-sources.jar
wget https://search.maven.org/remotecontent?filepath=grizzly/grizzly/1.0.28/grizzly-1.0.28.pom
mv remotecontent?filepath=grizzly%2Fgrizzly%2F1.0.28%2Fgrizzly-1.0.28.pom pom.xml

# Build and Test
mvn clean install
mvn test
