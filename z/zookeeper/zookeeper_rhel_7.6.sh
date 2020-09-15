# ----------------------------------------------------------------------------
#
# Package	: Apache Zookeeper
# Version	: 3.5.5
# Source repo	: https://github.com/apache/zookeeper.git
# Tested on	: rhel_7.6
# Script License: Apache License, Version 2 or later
# Maintainer	: lysannef@us.ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

if [ "$#" -gt 0 ]
then
    VERSION=$1
else
    VERSION="3.5.5"
fi

# Install dependencies.
yum update -y
yum install git wget java-11-openjdk-devel hostname -y

wget https://www-eu.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz
tar -xf apache-maven-3.6.2-bin.tar.gz -C /usr/local
ln -s /usr/local/apache-maven-3.6.2/bin/mvn /usr/bin/mvn
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.3.7-0.el7_6.ppc64le

# Build
cd $HOME
wget https://github.com/apache/zookeeper/archive/release-$VERSION.tar.gz
tar -xvzf release-$VERSION.tar.gz
cd zookeeper-release-$VERSION
mvn clean install -DskipTests

# Test
adduser testuser
chown testuser -R /zookeeper
su testuser -c 'mvn test -DforkCount=4'
