# ----------------------------------------------------------------------------
#
# Package	: py4j
# Version	: 0.10.4
# Source repo	: https://github.com/bartdag/py4j.git
# Tested on	: rhel_7.3
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
sudo yum update -y
sudo yum install -y git wget gcc java-1.7.0-openjdk-devel.ppc64le

export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk
export  PATH=$JAVA_HOME/bin:$PATH

# Install maven.
wget https://archive.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
tar -zxf apache-maven-3.3.3-bin.tar.gz
sudo cp -R apache-maven-3.3.3 /usr/local
sudo ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/bin/mvn

# Clone and build source code.
git clone https://github.com/bartdag/py4j.git
cd py4j/py4j-java
sudo mvn install
mvn test
