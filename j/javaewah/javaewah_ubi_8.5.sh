#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package          : javaewah
# Version          : master
# Source repo      : https://github.com/lemire/javaewah
# Tested on        : UBI 8.5
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : valipi_venkatesh@persistent.com
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

PACKAGE_NAME=javaewah
PACKAGE_VERSION=master
PACKAGE_URL=https://github.com/lemire/javaewah

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

#Dependencies
yum install -y java-17-openjdk-devel wget git 
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin
#java -version

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.9.1/binaries/apache-maven-3.9.1-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.9.1-bin.tar.gz
rm -rf tar xzvf apache-maven-3.9.1-bin.tar.gz
mv /usr/local/apache-maven-3.9.1 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
if ! mvn clean install -DskipTests -Dgpg.skip=true ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! mvn test ; then
    echo "------------------$PACKAGE_NAME::Build_success_but_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_success_but_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
