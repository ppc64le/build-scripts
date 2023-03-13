#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : atlas
# Version        : v2.3.0
# Source repo    : https://github.com/apache/atlas.git
# Tested on      : UBI 8.5
# Language       : JAVA
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Ambuj Kumar <Ambuj.kumar3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# Automated build is disabled as it takes > 50 min to build the package.
# ----------------------------------------------------------------------------


PACKAGE_VERSION=${1:-release-2.3.0}
PACKAGE_URL=https://github.com/apache/atlas
yum install git wget -y
yum install java-1.8.0-openjdk-devel -y
yum -y update && yum install -y yum-utils nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git gcc gcc-c++ libffi libffi-devel jq make cmake

dnf module reset -y nodejs
dnf module enable -y nodejs:18
dnf module install -y nodejs:18
npm install -g npm@9.5.1
npm install -g node-sass
npm install -g node-gyp
npm install yarn --global

ln -sf /usr/bin/python3 /usr/bin/python
cd /opt/
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzf apache-maven-3.6.3-bin.tar.gz
ln -sf apache-maven-3.6.3 maven
rm -rf apache-maven-3.6.3-bin.tar.gz
export MVN_HOME=/opt/maven
export PATH=${MVN_HOME}/bin:${PATH}
mvn -version
export MAVEN_OPTS="-Xms2g -Xmx2g"
if [ -d "/opt/atlas" ]
then
rm -rf /opt/atlas
fi
git clone $PACKAGE_URL
cd atlas
git checkout $PACKAGE_VERSION
#cp /atlas_v2.3.0.patch .
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/a/apache-atlas/apache-atlas_v2.3.0.patch;
git apply apache-atlas_v2.3.0.patch;
if ! mvn clean install -DskipTests ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi
#mvn clean install -DskipTests
rm -rf distro/target/atlas-distro-2.3.0.jar
if [ ! mvn install ] ; then
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

