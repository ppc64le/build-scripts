# ----------------------------------------------------------------------------
#
# Package	: jetty
# Version	: 9.4.12
# Source repo	: https://github.com/eclipse/jetty.project.git
# Tested on	: rhel_7.4
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
sudo yum -y install git wget java-1.8.0-openjdk-devel.ppc64le

# Install maven.
wget http://archive.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
tar -xvzf apache-maven-3.3.3-bin.tar.gz
sudo cp -R apache-maven-3.3.3 /usr/local
sudo ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/bin/mvn

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# Clone and build source.
git clone https://github.com/eclipse/jetty.project.git
cd jetty.project
mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V
