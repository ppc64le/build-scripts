#!/bin/bash
#---------------------------------------------------------------------------------------------------
#
# Package		: Neo4j
# Version		: 5.5.0
# Source repo		: https://github.com/neo4j/neo4j.git
# Tested on		: UBI 8.6 (docker)
# Language		: Java
# Travis-Check		: false
# Script License	: Apache License, Version 2 or later
# Maintainer		: Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#---------------------------------------------------------------------------------------------------

set -eux

CWD=$(pwd)
NEO4J_VERSION=5.5.0
MAVEN_VERSION=3.8.8
GOSU_VERSION=1.16

#Install RHEL deps
yum install java-17-openjdk-devel git wget curl hostname -y \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-ppc64el" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

#Install maven
wget https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar xvf apache-maven-${MAVEN_VERSION}-bin.tar.gz
rm -rf apache-maven-${MAVEN_VERSION}-bin.tar.gz
PATH=$CWD/apache-maven-${MAVEN_VERSION}/bin:$PATH

#Clone
git clone https://github.com/neo4j/neo4j.git
cd neo4j && git checkout ${NEO4J_VERSION}

#Add hostname
HOST=$(hostname)
echo "127.0.0.1   $HOST" >> /etc/hosts

#Patch
sed -i.bak '276d' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java
sed -i '276i \ \ \ \ \ \ \ \ \ \ \ \ if (bufferAlignment == UnsafeUtil.pageSize()) {' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java
sed -i '277i \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ address = memoryAllocator.allocateAligned(getCachePageSize(), getCachePageSize());' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java
sed -i '278i \ \ \ \ \ \ \ \ \ \ \ \ } else {' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java
sed -i '279i \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ address = memoryAllocator.allocateAligned(getCachePageSize(), bufferAlignment);' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java
sed -i '280i \ \ \ \ \ \ \ \ \ \ \ \ }' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java

#Build and test
export MAVEN_OPTS="-Xmx4096m"
ret=0
mvn clean install -DskipTests || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Build failed."
	exit 1
fi
mvn clean install || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Tests failed."
	exit 2
fi
echo "SUCCESS: Build and test success!"
