# ----------------------------------------------------------------------------
#
# Package	: marathon-client
# Version	: 0.4.10
# Source repo	: https://github.com/willroden/marathon-client
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
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
sudo apt-get install -y maven git wget openjdk-8-jdk openjdk-8-jre
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# Install maven.
wget https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.3.3/apache-maven-3.3.3-bin.tar.gz
tar -zxf apache-maven-3.3.3-bin.tar.gz
sudo cp -R apache-maven-3.3.3 /usr/local
sudo ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/bin/mvn

# Clone and build source code.
git clone https://github.com/willroden/marathon-client
cd marathon-client
mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V
mvn test -B
