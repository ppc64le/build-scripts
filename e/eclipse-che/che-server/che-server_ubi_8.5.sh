#!/bin/bash -ex
# ------------------------------------------------------------------------------
#
# Package	: che-server
# Version	: 7.59.0
# Source repo	: https://github.com/eclipse-che/che-server
# Tested on	: UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Haritha Patchari <haritha.patchari@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=https://github.com/eclipse-che/che-server
PACKAGE_VERSION=7.59.0
PACKAGE_URL=https://github.com/eclipse-che/che-server

yum update -y
yum install -y git wget

yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.18.0.10-2.el8_7.ppc64le
export PATH=$PATH:$JAVA_HOME/bin
cd $JAVA_HOME/bin/

# Install Maven

wget http://mirrors.estointernet.in/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -xvzf apache-maven-3.6.3-bin.tar.gz
export MVN_HOME=$(pwd)
export PATH=$PATH:$MVN_HOME/apache-maven-3.6.3/bin/

git clone https://github.com/eclipse-che/che-server.git
cd che-server
git checkout $PACKAGE_VERSION

# Build & Test
# mvn clean install
mvn -B clean install -U -Pintegration


