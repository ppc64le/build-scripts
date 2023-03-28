#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : vert.x
# Version       : 4.3.7
# Source repo   : https://github.com/eclipse-vertx/vert.x
# Tested on     : UBI 8.6
# Language      : JAVA
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shreya Kajbaje <Shreya.Kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=vert.x
PACKAGE_VERSION=${1:-4.3.7}
PACKAGE_URL=https://github.com/eclipse-vertx/vert.x.git

yum update -y
yum install git wget  gcc gcc-c++ openssl  -y
dnf install java-1.8.0-openjdk-devel -y

MAVEN_VERSION=${MAVEN_VERSION:-3.8.5}
wget http://mirrors.estointernet.in/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

ls /usr/local
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
ls /usr/local
rm apache-maven-$MAVEN_VERSION-bin.tar.gz
export M2_HOME=/usr/local/maven

if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! mvn package; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! mvn test; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi

mvn -Dtest="Http1xProxyTest" surefire:test
mvn -Dtest="Http1xMetricsTest" surefire:test
mvn -Dtest="Http2TracerTest" surefire:test
mvn -Dtest="MetricsTest" surefire:test
mvn -Dtest="MetricsContextTest" surefire:test
mvn -Dtest="StartStopListCommandsTest" surefire:test
mvn -Dtest="RunCommandTest" surefire:test

mvn test -PtestNativeTransport

mvn test -PtestDomainSockets

#tests failing due to netty issue refer links for the same -
#https://github.com/netty/netty-tcnative/issues/531
#https://jazz06.rchland.ibm.com:12443/jazz/web/projects/Power%20Ecosystem#action=com.ibm.team.workitem.viewWorkItem&id=154423
#https://github.com/eclipse-vertx/vert.x/issues/4227
#https://github.com/netty/netty/issues/12432
