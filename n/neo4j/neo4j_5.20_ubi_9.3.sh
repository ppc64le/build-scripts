#!/bin/bash -e
#---------------------------------------------------------------------------------------------------
#
# Package       : neo4j
# Version       : 5.20
# Source repo   : https://github.com/neo4j/neo4j.git
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

CWD=$(pwd)
PACKAGE_NAME=neo4j
PACKAGE_URL=https://github.com/neo4j/neo4j.git
PACKAGE_VERSION=${1:-5.20}

MAVEN_VERSION=3.8.8
GOSU_VERSION=1.16

export PATH=$PATH:/usr/local/bin
ulimit -n 65536

#Install RHEL deps
yum install java-17-openjdk-devel git wget hostname procps-ng -y \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-ppc64el" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-17-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

#install sbt package
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum -y install sbt


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
unset JAVA_OPTS
unset MAVEN_OPTS
MAVEN_OPTS="-Xmx666m"
JAVA_OPTS="-Xmx666m"

#Build and test
if !  mvn clean install -DskipTests  ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

# Tests 
if ! mvn clean install -Dlog4j.configurationFile="/tmp/log" -pl -:kernel-it,-:neo4j-kernel-test,-:neo4j-collections,-:bolt-it,-:neo4j-cypher-planner,-:neo4j-cypher-expression-evaluator,-:gbptree-tests ; then
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
