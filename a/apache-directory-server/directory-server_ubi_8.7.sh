#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	    : apache-directory-server
# Version	    : master
# Source repo	    : https://github.com/apache/directory-server
# Tested on	    : ubi 8.7
# Language          : java
# Ci-Check      : true
# Script License    : Apache License, Version 2 or later
# Maintainer	    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#Variables
PACKAGE_NAME=directory-server
PACKAGE_VERSION=${1:-"master"}
PACKAGE_URL=https://github.com/apache/directory-server

#Install dependencies
yum install -y git wget gcc-c++ gcc make autoconf automake pkgconfig libtool rpm-build binutils openssl-devel

#Setup java environment
yum install -y java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
# update the path env. variable 
export PATH=$PATH:$JAVA_HOME/bin
 
#Install maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.5}
wget http://mirrors.estointernet.in/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
ls /usr/local
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
ls /usr/local
rm apache-maven-$MAVEN_VERSION-bin.tar.gz
export M2_HOME=/usr/local/maven
# update the path env. variable
export PATH=$PATH:$M2_HOME/bin

#clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build and Test
if ! mvn clean install; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
