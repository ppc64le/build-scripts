#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : camel
# Version          : 4.10.2
# Source repo      : https://github.com/apache/camel.git
# Tested on        : UBI:9.3
# Language         : Java
# Ci-Check     : True 
# Script License   : Apache License, Version 2 or later
# Maintainer       : Anushka Juli<anushka.juli1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=camel
PACKAGE_VERSION=${1:-camel-4.12.0}
PACKAGE_URL=https://github.com/apache/camel.git

# install tools and dependent packages
echo "Installing dependencies"
yum install -y git wget tar

#install java17
echo "Installing java17"
yum install -y java-17-openjdk-devel
JDK_PATHS=$(compgen -G '/usr/lib/jvm/java-17-openjdk-*')
export JAVA_HOME=${JDK_PATHS%$'\n'*}
export PATH=$JAVA_HOME/bin:$PATH
echo "Installed JAVA"

#install maven
echo "Installing maven"
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
echo "building camel"
if ! mvn -Dsurefire.testFailureIgnore=true -Dmaven.test.failure.ignore=true clean install; then
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
