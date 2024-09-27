#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : spring-amqp
# Version          : v3.1.7
# Source repo      : https://github.com/spring-projects/spring-amqp
# Tested on        : UBI:9.3
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Mayur Bhosure <Mayur.Bhosure2@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME=spring-amqp
PACKAGE_URL=https://github.com/spring-projects/spring-amqp.git
PACKAGE_VERSION=${1:-v3.1.7}

yum install git wget gcc gcc-c++ unzip java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless -y
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME

export GRADLE_VERSION="8.5"
# download gradle distribution
wget https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip -q -O /tmp/gradle-$GRADLE_VERSION-bin.zip

# unzip and install
unzip -d /tmp /tmp/gradle-$GRADLE_VERSION-bin.zip
mv /tmp/gradle-$GRADLE_VERSION /usr/local/gradle
export PATH=/usr/local/gradle/bin/:$PATH

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! gradle clean build -x javadoc ; then
     echo "------------------$PACKAGE_NAME:Build_fails---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails_"
     exit 2
fi

if !  gradle check ; then
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
