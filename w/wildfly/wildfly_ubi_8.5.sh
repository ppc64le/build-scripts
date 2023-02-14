#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package        : Wildfly
# Version        : 27.0.0.Alpha5, 27.0.0.Final
# Source repo    : https://github.com/wildfly/wildfly.git
# Language       : Java
# Travis-Check   : True
# Tested on      : UBI 8.5
# Script License : GNU Lesser General Public License Version 2.1
# Maintainer     : Vindo K <Vinod.K1@ibm.com>, Shreya Kajbaje <Shreya.Kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=wildfly
PACKAGE_VERSION=${1:-27.0.0.Alpha5}
PACKAGE_URL=https://github.com/wildfly/wildfly.git

yum update -y
yum install -y git wget  tar

yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin


# Install maven.
cd /opt/
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzf apache-maven-3.6.3-bin.tar.gz
ln -s apache-maven-3.6.3 maven
export MVN_HOME=/opt/maven
export PATH=${MVN_HOME}/bin:${PATH}
mvn -version

cd /home
rm -rf $PACKAGE_NAME
git clone $PACKAGE_URL

cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

mvn install

mvn clean install -DskipTests
