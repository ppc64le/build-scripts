#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : jaf-api
# Version          : 2.1.3
# Source repo      : https://github.com/jakartaee/jaf-api
# Tested on        : UBI:9.3
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------
# Variables
PACKAGE_NAME=jaf-api
PACKAGE_URL=https://github.com/jakartaee/jaf-api
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-2.1.3}

yum install -y java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless git wget gcc gcc-c++ 
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#installing maven 
wget https://archive.apache.org/dist/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz
tar -zxf apache-maven-3.8.1-bin.tar.gz
cp -R apache-maven-3.8.1 /usr/local
ln -s /usr/local/apache-maven-3.8.1/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd api
if ! mvn clean install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi
if ! mvn test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
