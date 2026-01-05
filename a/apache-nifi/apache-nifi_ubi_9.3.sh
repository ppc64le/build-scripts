#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : apache-nifi
# Version          : rel/nifi-2.0.0-M4
# Source repo      : https://github.com/apache/nifi
# Tested on        : UBI:9.3
# Language         : Javas
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

PACKAGE_NAME=nifi
PACKAGE_URL=https://github.com/apache/nifi
PACKAGE_VERSION=${1:-rel/nifi-2.0.0-M4}

yum install -y java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless git wget gcc gcc-c++
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin

wget https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz
tar -zxf apache-maven-3.9.6-bin.tar.gz
cp -R apache-maven-3.9.6 /usr/local
ln -s /usr/local/apache-maven-3.9.6/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./mvnw -V -nsu -ntp -ff install -D skipTests -am -pl :nifi-python-framework -pl :nifi-python-extension-api -pl :nifi-python-test-extensions -pl nifi-system-tests/nifi-system-test-suite -pl nifi-system-tests/nifi-stateless-system-test-suite -pl -:nifi-frontend ; then
     echo "------------------$PACKAGE_NAME:Install_fails---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
     exit 2
fi

if ! ./mvnw -V -nsu -ntp -ff test -pl :nifi-python-framework -pl :nifi-python-extension-api -pl :nifi-python-test-extensions -pl nifi-system-tests/nifi-system-test-suite -pl nifi-system-tests/nifi-stateless-system-test-suite ; then
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
