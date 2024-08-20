#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : failsafe
# Version          : failsafe-parent-3.3.2
# Source repo      : https://github.com/failsafe-lib/failsafe.git
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

PACKAGE_NAME=failsafe
PACKAGE_VERSION=${1:-failsafe-parent-3.3.2}
PACKAGE_URL=https://github.com/failsafe-lib/failsafe.git

# Install dependencies.
sudo yum install -y yum-utils git wget tar java-17-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
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

export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# Clone failsafe repo
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! mvn install -DskipTests=true; then
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