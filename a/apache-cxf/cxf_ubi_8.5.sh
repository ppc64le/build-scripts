#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : cxf
# Version       : cxf-4.0.0
# Source repo   : https://github.com/apache/cxf
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=cxf
PACKAGE_VERSION=${1:-cxf-4.0.0}
PACKAGE_URL=https://github.com/apache/cxf.git

yum -y update
yum install -y git make wget gcc-c++ java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin
#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.6.3-bin.tar.gz
rm -rf tar xzvf apache-maven-3.6.3-bin.tar.gz
mv /usr/local/apache-maven-3.6.3 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

cd $WORKDIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! mvn clean install -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -DskipTests ; then
    echo "------------------$PACKAGE_NAME:Install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

export MAVEN_OPTS="-Xmx2048m -Xms1024m  -Djava.awt.headless=true"

wget https://raw.githubusercontent.com/vinodk99/build-scripts/apache-cxf/a/apache-cxf/cxf.patch;
git apply cxf.patch 
if ! mvn -U -B clean install ; then
    echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Install_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
