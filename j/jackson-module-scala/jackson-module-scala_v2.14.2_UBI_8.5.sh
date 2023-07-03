#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : jackson-module-scala
# Version          : v2.14.2
# Source repo      : https://github.com/FasterXML/jackson-module-scala
# Tested on        : UBI 8.5
# Language         : Scala
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=jackson-module-scala
PACKAGE_URL=https://github.com/FasterXML/jackson-module-scala
PACKAGE_VERSION=${1:-v2.14.2}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)


yum install -y curl unzip wget git maven
yum install -y java-11-openjdk.ppc64le java-11-openjdk-devel.ppc64le

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le
export PATH=$PATH:$JAVA_HOME/bin

rm -f /etc/yum.repos.d/bintray-rpm.repo
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum install -y sbt

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! sbt compile; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! sbt test; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

