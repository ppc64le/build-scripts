#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : quarkusio/quarkus
# Version       : 3.2.0.Final
# Source repo   : https://github.com/quarkusio/quarkus.git
# Tested on     : Linux k8s-b800e3-bastion-1.power-iaas.cloud.ibm.com 4.18.0-425.19.2.el8_7.ppc64le
# Language      : Java
# Travis-Check  : False
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

PACKAGE_NAME=quarkus
PACKAGE_VERSION=${1:-3.2.0.Final}
PACKAGE_URL=https://github.com/quarkusio/quarkus.git

#java installation
yum install -y -q java-17-openjdk
yum install -y -q java-17-openjdk-devel

jdk_path=$(ls /usr/lib/jvm/ | grep -P "^(?=.*java-17)(?=.*$HW_ARCH)")
export JAVA_HOME=/usr/lib/jvm/$jdk_path
jre_path=$(ls /usr/lib/jvm/ | grep -P "^(?=.*jre-17)(?=.*$HW_ARCH)")
export JRE_HOME=/usr/lib/jvm/$jre_path
export PATH=$PATH:$JAVA_HOME/bin
alternatives --set java $JAVA_HOME/bin/java
alternatives --set javac $JAVA_HOME/bin/javac

#maven installation
MAVEN_VERSION=3.9.3
wget -q https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION $M2_HOME
M2_HOME="${M2_HOME:-/usr/local/maven}"
mvn -version

#apply patch
git reset --hard
patch -p1 < quarktest.patch

#build and test quarkus
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! MAVEN_OPTS="-Xmx4g" ./mvnw -Dquickly; then
    echo "------------------$PACKAGE_NAME:build_&_test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi