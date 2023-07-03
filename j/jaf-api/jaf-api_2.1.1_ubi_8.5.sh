#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jaf-api
# Version	: 2.1.1
# Source repo	: https://github.com/jakartaee/jaf-api
# Tested on	: UBI 8.5
# Language      : Java, Html, Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jaf-api
PACKAGE_VERSION=${1:-2.1.1}
PACKAGE_URL=https://github.com/jakartaee/jaf-api

yum -y update
yum install -y gcc-c++ gcc npm wget curl unzip nano make git

MAVEN_VERSION=3.6.3
wget http://mirrors.estointernet.in/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
rm apache-maven-$MAVEN_VERSION-bin.tar.gz
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

yum install -y java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless
 export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.18.0.10-2.el8_7.ppc64le
export PATH=$PATH:$JAVA_HOME/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd api
if ! mvn -B -V -U -C -Poss-release clean verify org.glassfish.copyright:glassfish-copyright-maven-plugin:check -Dgpg.skip=true -Dcopyright.ignoreyear=true; then
    echo "Build and test fails"
    exit 2
else
    echo "Build and test successful"
    exit 0
fi