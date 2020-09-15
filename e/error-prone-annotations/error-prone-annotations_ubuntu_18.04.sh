# ----------------------------------------------------------------------------
#
# Package       : Error Prone Annotations
# Version       : 2.3.2-SNAPSHOT
# Source repo   : https://github.com/google/error-prone.git
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
sudo apt-get install -y git openjdk-8-jdk ant maven

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# Download source-jar
cd $HOME
git clone https://github.com/google/error-prone.git && cd $HOME/error-prone/annotation

# Build and Test
mvn clean install
mvn test
