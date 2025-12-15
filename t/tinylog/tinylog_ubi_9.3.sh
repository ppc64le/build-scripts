#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : tinylog
# Version          : 2.7.0
# Source repo      : https://github.com/tinylog-org/tinylog.git
# Tested on        : UBI:9.3
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

#variables
PACKAGE_NAME=tinylog
PACKAGE_URL=https://github.com/tinylog-org/tinylog.git
PACKAGE_VERSION=${1:-2.7.0}

# install dependencies
yum install -y git wget 

#install java 9
wget https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk-9.0.4%2B11/OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz
tar -C /usr/local -zxf OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz
export JAVA_HOME=/usr/local/jdk-9.0.4+11
export PATH=$PATH:$JAVA_HOME/bin
rm -rf OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz
tar -zxf apache-maven-3.8.1-bin.tar.gz
cp -R apache-maven-3.8.1 /usr/local
ln -s /usr/local/apache-maven-3.8.1/bin/mvn /usr/bin/mvn

#clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build
if ! mvn clean install -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -DskipTests ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#test
if ! mvn clean verify -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -pl '!tinylog-impl' ; then
    echo "------------------$PACKAGE_NAME:Build_success_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail |  Build_Success_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
