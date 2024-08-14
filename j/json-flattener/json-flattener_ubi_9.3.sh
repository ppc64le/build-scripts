#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : json-flattener
# Version          : json-flattener-0.16.6
# Source repo      : https://github.com/wnameless/json-flattener.git
# Tested on        : UBI 9.3
# Language         : Java
# Travis-Check     : True 
# Script License   : Apache License, Version 2 or later
# Maintainer       : Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=json-flattener
PACKAGE_VERSION=${1:-json-flattener-0.16.6}
PACKAGE_URL=https://github.com/wnameless/json-flattener.git

# Install dependencies.
yum install -y yum-utils git wget tar java-11-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH
java -version

# Install Maven 3.8.8
cd $HOME
MAVEN_VERSION=3.8.8
wget https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
export PATH=$HOME/apache-maven-${MAVEN_VERSION}/bin:${PATH}

# Set ENV variables
export M2_HOME=$HOME/apache-maven-${MAVEN_VERSION}

# Clone json-flattener repo
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! mvn clean install -DskipTests=true -Dgpg.skip=true; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
elif ! mvn test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
