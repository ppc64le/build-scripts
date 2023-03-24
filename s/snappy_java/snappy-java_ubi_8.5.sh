#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: snappy-java
# Version	: 1.1.9.1
# Source repo	: https://github.com/xerial/snappy-java.git
# Tested on	: UBI: 8.5
# Language      : Java, C++
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

PACKAGE_NAME=snappy-java
PACKAGE_VERSION=${1:-v1.1.9.1}
PACKAGE_URL=https://github.com/xerial/snappy-java.git
HOME_DIR=${PWD}

yum update -y
yum install -y curl unzip wget git maven java-11-openjdk.ppc64le java-11-openjdk-devel.ppc64le make cmake gcc gcc-c++ libstdc++-static

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.18.0.10-2.el8_7.ppc64le
export PATH=$JAVA_HOME/bin:$PATH
java -version

#sbt installation
rm -f /etc/yum.repos.d/bintray-rpm.repo
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum install -y sbt


#Cloning snappy-java repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd snappy-java/
git checkout $PACKAGE_VERSION

#Build snappy-java
if ! make clean-native native; then
        echo "Build Fails"
        exit 1
fi

#Test snappy-java
if ! sbt test; then
        echo "Test Fails"
        exit 2
else
        echo "Build and Test Success"
        exit 0
fi