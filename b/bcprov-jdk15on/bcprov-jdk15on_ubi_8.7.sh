#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : bcprov-jdk15on
# Version          : r1rv73
# Source repo      : https://github.com/bcgit/bc-java.git
# Tested on        : UBI 8.7
# Language         : Java
# Travis-Check     : True
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

PACKAGE_NAME=prov
PACKAGE_VERSION=${1:-r1rv73}
PACKAGE_URL=https://github.com/bcgit/bc-java.git
HOME_DIR=${PWD}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git wget tar java-11-openjdk-devel unzip openssl-devel

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH
java -version

#Install Gradle tool
cd $HOME_DIR
wget https://services.gradle.org/distributions/gradle-7.6.1-bin.zip
unzip gradle-7.6.1-bin.zip
mkdir /opt/gradle
cp -pr gradle-7.6.1/* /opt/gradle
export PATH=/opt/gradle/bin:${PATH}

#Cloning bc-java repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd bc-java
git checkout $PACKAGE_VERSION
cd $PACKAGE_NAME/

#Cloning bc-test-data repo required for running tests
git clone https://github.com/bcgit/bc-test-data

cd $HOME_DIR/bc-java/prov
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"

#Build and test

if ! gradle build ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

if !  gradle test ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi




