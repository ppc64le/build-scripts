#!/bin/bash -e
#---------------------------------------------------------------------------------------------------
#
# Package       : janusgraph
# Version       : v1.1.0
# Source repo   : https://github.com/JanusGraph/janusgraph.git
# Tested on     : UBI 9.3 
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
#---------------------------------------------------------------------------------------------------

PACKAGE_NAME=janusgraph
PACKAGE_URL=https://github.com/JanusGraph/janusgraph.git
PACKAGE_VERSION=${1:-v1.1.0}

MAVEN_VERSION=3.8.8

#Install RHEL deps
yum install java-11-openjdk-devel git wget hostname procps-ng -y 
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

#Install maven
wget https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar xvf apache-maven-${MAVEN_VERSION}-bin.tar.gz
rm -rf apache-maven-${MAVEN_VERSION}-bin.tar.gz
PATH=$('pwd')/apache-maven-${MAVEN_VERSION}/bin:$PATH

#Clone
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}

unset JAVA_OPTS
unset MAVEN_OPTS
MAVEN_OPTS="-Xms256m -Xmx512m"
JAVA_OPTS="-Xms256m -Xmx512m"

#Build and test

export  ES_JAVA_OPTS="-Xms256m -Xmx512m"
export  BUILD_MAVEN_OPTS="-DskipTests=true --batch-mode --also-make"
export  VERIFY_MAVEN_OPTS="-Pcoverage"
#Build
if !  mvn clean install -Dlog4j.configurationFile="/tmp/log" -Pjanusgraph-release ${BUILD_MAVEN_OPTS} -Dgpg.skip=true -Pjava-11 -pl -:janusgraph-dist  ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

# Tests   janusgraph-dist, janusgraph-cql janusgraph-hbase,janusgraph-lucene,janusgraph-es,janusgraph-solr,janusgraph-dist,example-common,janusgraph-benchmark,janusgraph-scylla requires docker 
if !  mvn verify -Dlog4j2.configurationFile="/tmp/log4j2" -Dlog4j.configurationFile="/tmp/log4j" -Pjanusgraph-release -Dgpg.skip=true -Pjava-11 --batch-mode  -pl -:janusgraph-test,-:janusgraph-cql,-:janusgraph-hbase,-:janusgraph-lucene,-:janusgraph-es,-:janusgraph-solr,-:janusgraph-dist,-:example-common,-:janusgraph-benchmark,-:janusgraph-scylla,-:janusgraph-server -T 8 ; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
