# ----------------------------------------------------------------------------
#
# Package	: cryptacular
# Version	: 1.2.1
# Source repo	: https://github.com/vt-middleware/cryptacular
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

# Update source
sudo yum update -y

# Install dependencies
sudo yum install -y wget git ant java-1.8.0-openjdk.ppc64le \
    java-1.8.0-openjdk-devel.ppc64le
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin

WDIR=`pwd`

# Install maven
wget http://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
tar -xvzf apache-maven-3.3.9-bin.tar.gz
sudo cp -R apache-maven-3.3.9 /usr/local
sudo ln -s /usr/local/apache-maven-3.3.9/bin/mvn /usr/bin/mvn
export MAVEN_HOME="/usr/local/apache-maven-3.3.9"
rm -rf apache-maven-3.3.9 apache-maven-3.3.9.tar.gz

# Build and Install
cd $WDIR
git clone https://github.com/vt-middleware/cryptacular
cd cryptacular
mvn test
