#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : eclipse-che-server
# Version          : 7.106.0
# Source repo      : https://github.com/eclipse-che/che-server
# Tested on        : UBI:9.4
# Language         : Java
# Travis-Check     : True 
# Script License   : Apache License, Version 2
# Maintainer       : Prasanna Marathe<prasanna.marathe@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=che-server
PACKAGE_VERSION=${1:-7.106.0}
PACKAGE_URL=https://github.com/eclipse-che/che-server

# install tools and dependent packages
echo "Installing dependencies"
yum install -y git wget tar

#install java11
echo "Installing java11"
yum install -y java-11-openjdk-devel
JDK_PATHS=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JAVA_HOME=${JDK_PATHS%$'\n'*}
export PATH=$JAVA_HOME/bin:$PATH
echo "Installed JAVA 11"

#install maven
echo "Installing maven 3.9.9"
MAVEN_VERSION=${MAVEN_VERSION:-3.9.9}
wget https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -zxf apache-maven-$MAVEN_VERSION-bin.tar.gz
cp -R apache-maven-$MAVEN_VERSION /usr/local
ln -s /usr/local/apache-maven-$MAVEN_VERSION/bin/mvn /usr/bin/mvn
echo "Installed maven"

echo "cloning repository"
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build
echo "building che server"
if ! mvn clean install; then
    echo "------------------$PACKAGE_NAME:build fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build success---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass|  Build_success"
    exit 0
fi
