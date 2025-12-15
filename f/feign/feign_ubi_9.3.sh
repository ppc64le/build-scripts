#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : feign
# Version       : 13.3
# Source repo   : https://github.com/OpenFeign/feign
# Tested on     : UBI:9.3
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=feign
PACKAGE_VERSION=${1:-13.3}
PACKAGE_URL=https://github.com/OpenFeign/feign
 
#install dependencies
yum install -y git wget gcc-c++ gcc 
yum install -y java-11-openjdk java-11-openjdk-devel java-1.8.0-openjdk java-1.8.0-openjdk-devel java-17-openjdk java-17-openjdk-devel java-21-openjdk java-21-openjdk-devel
 
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:$JAVA_HOME
 
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME
 
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME
 
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME
 
#install maven 
wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz
tar -zxf apache-maven-3.8.7-bin.tar.gz
cp -R apache-maven-3.8.7 /usr/local
ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn
 
#copying toolchains.xml file to .m2 folder to exceute tests
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/f/feign/toolchains.xml
mkdir ~/.m2
cp toolchains.xml ~/.m2/

#clone repository
git clone $PACKAGE_URL 
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build 
if ! ./mvnw -ntp dependency:resolve-plugins go-offline:resolve-dependencies -DskipTests=true -B ;  then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1

fi
 
#test
if ! ./mvnw -ntp -B verify ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

 
