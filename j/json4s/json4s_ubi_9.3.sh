#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jon4s
# Version	: v4.1.0-M8
# Source repo	: https://github.com/json4s/json4s.git
# Tested on	: UBI: 9.3
# Language      : Scala
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=json4s
PACKAGE_VERSION=${1:-v4.1.0-M8}
PACKAGE_URL=https://github.com/json4s/json4s.git

yum install -y curl git java-11-openjdk-devel nodejs clang wget tar --allowerasing

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH
java -version

#Install Scala
wget https://github.com/lampepfl/dotty/releases/download/3.5.2/scala3-3.5.2.tar.gz
tar -xvf scala3-3.5.2.tar.gz
export PATH=$HOME/scala3-3.5.2/bin:$PATH

#Install sbt
rm -f /etc/yum.repos.d/bintray-rpm.repo
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum install -y sbt

# Clone json4s
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
export TZ=Australia/Canberra

if ! sbt compile ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
if ! sbt test ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi