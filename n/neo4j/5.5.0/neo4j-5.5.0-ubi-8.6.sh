#!/bin/bash
#---------------------------------------------------------------------------------------------------
#
# Package		: Neo4j
# Version		: 5.5.0
# Source repo		: https://github.com/neo4j/neo4j.git
# Tested on		: UBI 8.6 (docker)
# Language		: Java
# Travis-Check		: true
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

#Install RHEL deps
yum install java-17-openjdk git wget curl -y \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-ppc64el" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

#Install maven
wget https://dlcdn.apache.org/maven/maven-3/3.9.0/binaries/apache-maven-3.9.0-bin.tar.gz
tar xvf apache-maven-3.9.0-bin.tar.gz
rm -rf apache-maven-3.9.0-bin.tar.gz
PATH=$CWD/apache-maven-3.9.0/bin:$PATH

#Clone
git clone https://github.com/neo4j/neo4j.git
cd neo4j && git checkout 5.5.0

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
mvn clean install
