# ----------------------------------------------------------------------------
#
# Package       : Util Geolocation Ejb
# Version       : 1.0.31
# Source repo   : http://repo1.maven.org/maven2/org/ow2/util/util-geolocation-ejb/1.0.31
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
sudo apt-get install -y wget maven openjdk-8-jdk

#Download source jar and pom.xml file
mkdir util_geolocation_ejb && cd util_geolocation_ejb
wget http://repo1.maven.org/maven2/org/ow2/util/util-geolocation-ejb/1.0.31/util-geolocation-ejb-1.0.31-sources.jar
jar -xvf util-geolocation-ejb-1.0.31-sources.jar

wget http://repo1.maven.org/maven2/org/ow2/util/util-geolocation-ejb/1.0.31/util-geolocation-ejb-1.0.31.pom
mv util-geolocation-ejb-1.0.31.pom pom.xml

# Build and Test
mvn clean install
mvn test
