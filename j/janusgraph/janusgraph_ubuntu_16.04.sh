# ----------------------------------------------------------------------------
#
# Package	: JanusGraph
# Version	: 0.2.0 
# Source repo	: https://github.com/JanusGraph/janusgraph.git 
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update
sudo apt-get install openjdk-8-jdk wget git -y
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el/

wget http://www-eu.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz
tar xzvf apache-maven-3.5.2-bin.tar.gz
export PATH=$PATH:`pwd`/apache-maven-3.5.2/bin
git clone https://github.com/JanusGraph/janusgraph.git
## Build and test JanusGraph
cd janusgraph
mvn clean install

## Note ##
# Running build Without Tests
# mvn clean install -DskipTests=true
# Then Running Tests saperately 
# mvn test
# Running build and test in same command 
# mvn clean install
