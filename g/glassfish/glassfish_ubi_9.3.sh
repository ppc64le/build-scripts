#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : glassfish
# Version       : 7.0.15
# Source repo   : https://github.com/eclipse-ee4j/glassfish
# Tested on     : UBI:9.3
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=glassfish
PACKAGE_URL=https://github.com/eclipse-ee4j/glassfish
PACKAGE_VERSION=${1:-7.0.15}

yum install -y git wget

# Install Java 
wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.6%2B10/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.6_10.tar.gz
tar -C /usr/local -xzf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.6_10.tar.gz
export JAVA_HOME=/usr/local/jdk-17.0.6+10
export JAVA17_HOME=/usr/local/jdk-17.0.6+10
export PATH=$PATH:/usr/local/jdk-17.0.6+10/bin
ln -sf /usr/local/jdk-17.0.6+10/bin/java /usr/bin
rm -f OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.6_10.tar.gz
java -version

# Install maven
wget https://dlcdn.apache.org/maven/maven-3/3.9.8/binaries/apache-maven-3.9.8-bin.tar.gz
tar -xvzf apache-maven-3.9.8-bin.tar.gz
cp -R apache-maven-3.9.8 /usr/local
ln -s /usr/local/apache-maven-3.9.8/bin/mvn /usr/bin/mvn
rm -f apache-maven-3.9.8-bin.tar.gz
mvn -version

# Set MAVEN_OPTS environment variable
export MAVEN_OPTS="-Xmx2500m -Xss768k -XX:+UseG1GC -XX:+UseStringDeduplication"

# Clone package repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build, clean and test
if ! mvn -B -e clean install -Pfastest,staging -T4C; then
	echo "------------------$PACKAGE_NAME:install_and_test_both_fail---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME |   $PACKAGE_VERSION    |   Fail    |   Install_Success_but_Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME |   $PACKAGE_VERSION    |   Pass    |   Install_and_Test_Success"
	exit 0
fi


