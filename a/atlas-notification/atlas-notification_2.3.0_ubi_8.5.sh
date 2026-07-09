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
cd /opt/
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzf apache-maven-3.6.3-bin.tar.gz
ln -sf apache-maven-3.6.3 maven
rm -rf apache-maven-3.6.3-bin.tar.gz
export MVN_HOME=/opt/maven
export PATH=${MVN_HOME}/bin:${PATH}
mvn -version
export MAVEN_OPTS="-Xms2g -Xmx2g"

git clone $PACKAGE_URL
cd atlas
git checkout $PACKAGE_VERSION
cd build-tools
mvn clean install
cd ..
cd notification
mvn install
