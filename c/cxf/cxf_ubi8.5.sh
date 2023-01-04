#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: cxf
# Version	: cxf-4.0.0
# Source repo	: https://github.com/apache/cxf
# Tested on	: UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=cxf
PACKAGE_VERSION=${1:cxf-4.0.0}
PACKAGE_URL=https://github.com/apache/cxf.git
WORKDIR=`pwd`

yum -y update
yum install -y git make wget gcc-c++ java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless 

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz
tar -zxf apache-maven-3.8.1-bin.tar.gz
cp -R apache-maven-3.8.1 /usr/local
ln -s /usr/local/apache-maven-3.8.1/bin/mvn /usr/bin/mvn

# Clone and build source code.
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
mvn process-classes compile -Pnochecks -DskipTests
