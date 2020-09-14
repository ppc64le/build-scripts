# ----------------------------------------------------------------------------
#
# Package       : castor
# Version       : 1.4.0
# Source repo   : https://github.com/castor-data-binding/castor
# Tested on     : ubuntu_18.04
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

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y git openjdk-8-jdk maven

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el

# Clone and build source.
git clone https://github.com/castor-data-binding/castor.git
cd castor/
mkdir -p ~/.gradle && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties
mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V
mvn test -B
