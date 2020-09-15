# ----------------------------------------------------------------------------
#
# Package	: JanusGraph
# Version	: 0.2.0 
# Source repo	: https://github.com/JanusGraph/janusgraph.git 
# Tested on	: rhel_7.4
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

sudo yum update -y
sudo yum -y install java-1.8.0-openjdk-devel wget git
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

wget http://www-eu.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz
tar xzvf apache-maven-3.5.2-bin.tar.gz
export PATH=$PATH:`pwd`/apache-maven-3.5.2/bin
rm -rf apache-maven-3.5.2-bin.tar.gz
## Build and test JanusGraph
git clone https://github.com/JanusGraph/janusgraph.git
cd janusgraph
mvn clean install

## Note ##
# Running build Without Tests
# mvn clean install -DskipTests=true
# Then Running Tests saperately 
# mvn test
