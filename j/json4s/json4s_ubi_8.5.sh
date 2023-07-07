#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jon4s
# Version	: v4.1.0-M2
# Source repo	: https://github.com/json4s/json4s.git
# Tested on	: UBI: 8.5
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
PACKAGE_VERSION=${1:-v4.1.0-M2}
PACKAGE_URL=https://github.com/json4s/json4s.git
HOME_DIR=${PWD}

yum update -y
yum install -y curl git java-1.8.0-openjdk-devel nodejs nodejs-devel clang wget tar

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.362.b09-2.el8_7.ppc64le
export PATH=$JAVA_HOME/bin:$PATH
java -version

#Install Scala
cd $HOME_DIR
wget https://github.com/lampepfl/dotty/releases/download/3.2.1/scala3-3.2.1.tar.gz
tar -xvf scala3-3.2.1.tar.gz
export PATH=$HOME_DIR/scala3-3.2.1/bin:$PATH

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

if ! sbt compile; then
	echo "Build Fails"
	exit 1
elif ! sbt test; then
	echo "Test Fails"
	exit 2
else
	echo "Build and Test Success"
	exit 0
fi