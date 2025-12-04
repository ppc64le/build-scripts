#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ci.gradle
# Version          : liberty-gradle-plugin-3.8.3
# Source repo      : https://github.com/OpenLiberty/ci.gradle/
# Tested on        : UBI:9.3
# Language         : Groovy,Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME=ci.gradle
PACKAGE_URL=https://github.com/OpenLiberty/ci.gradle
PACKAGE_VERSION=${1:-liberty-gradle-plugin-3.8.3}

yum install git wget gcc gcc-c++ java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless -y
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME

wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz
tar -zxf apache-maven-3.8.7-bin.tar.gz
cp -R apache-maven-3.8.7 /usr/local
ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

git clone https://github.com/OpenLiberty/ci.common
git clone https://github.com/OpenLiberty/ci.ant

mvn -V clean install -f ci.ant --batch-mode --no-transfer-progress --errors -DtrimStackTrace=false -DskipTests
mvn -V clean install -f ci.common --batch-mode --no-transfer-progress --errors -DtrimStackTrace=false -DskipTests

#Build and test for ol and wl modules.
if ! ./gradlew build -x test ; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails_"
        exit 1
fi

#Test for ol module
if ! ./gradlew clean install check -P"test.include"="**/TestCompileJSPSource21*" -Druntime=ol -DruntimeVersion="24.0.0.6" ; then
       echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
       echo "$PACKAGE_URL $PACKAGE_NAME"
       echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
       exit 2
fi

#Test for wl module
if ! ./gradlew clean install check -P"test.include"="**/TestCompileJSPSource21*" -Druntime=wl -DruntimeVersion="24.0.0.6" ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
      exit 1
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi