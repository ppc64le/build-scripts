#!/bin/bash -e
#---------------------------------------------------------------------------------------------------
#
# Package		: Neo4j
# Version		: 5.9.0
# Source repo		: https://github.com/neo4j/neo4j.git
# Tested on		: UBI 8.7 (docker)
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

CWD=$(pwd)
PACKAGE_NAME=neo4j
PACKAGE_URL=https://github.com/neo4j/neo4j.git
PACKAGE_VERSION=5.9.0
MAVEN_VERSION=3.8.8
GOSU_VERSION=1.16

export PATH=$PATH:/usr/local/bin
ulimit -s 65536

#Install RHEL deps
yum install java-17-openjdk-devel git wget curl hostname procps-ng -y \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-ppc64el" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-17-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

#Install maven
wget https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar xvf apache-maven-${MAVEN_VERSION}-bin.tar.gz
rm -rf apache-maven-${MAVEN_VERSION}-bin.tar.gz
PATH=$CWD/apache-maven-${MAVEN_VERSION}/bin:$PATH

#Clone
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}

#Add hostname
HOST=$(hostname)
echo "127.0.0.1   $HOST" >> /etc/hosts

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
