# ----------------------------------------------------------------------------
#
# Package       : Findbugs JSR305
# Version       : 3.0.2
# Source repo   : http://central.maven.org/maven2/com/google/code/findbugs/jsr305/3.0.2/jsr305-3.0.2-sources.jar
# Tested on     : ubuntu_16.04
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
sudo apt-get install -y wget openjdk-8-jdk maven

# Download source-jar and pom.xml files
mkdir jsr305
cd jsr305
wget http://central.maven.org/maven2/com/google/code/findbugs/jsr305/3.0.2/jsr305-3.0.2-sources.jar
wget http://central.maven.org/maven2/com/google/code/findbugs/jsr305/3.0.2/jsr305-3.0.2.pom

# Extract the source from the jar
jar -xvf jsr305-3.0.2-sources.jar
mv jsr305-3.0.2.pom pom.xml

# Build and Test
mvn clean install -Dgpg.skip
mvn test
