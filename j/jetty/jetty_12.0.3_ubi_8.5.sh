#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : jetty
# Version		: 12.0.3
# Source repo	: https://github.com/eclipse/jetty.project.git
# Tested on	    : UBI: 8.7
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_URL=https://github.com/eclipse/jetty.project.git
PACKAGE_VERSION=${1:-jetty-12.0.3}

# Install dependencies.
yum -y install git wget java-17-openjdk-devel.ppc64le

# Install maven.
wget https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
tar -xvzf apache-maven-3.9.5-bin.tar.gz
cp -R apache-maven-3.9.5 /usr/local
ln -s /usr/local/apache-maven-3.9.5/bin/mvn /usr/bin/mvn

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# Clone and build source.
git clone https://github.com/eclipse/jetty.project.git
cd jetty.project && git checkout $PACKAGE_VERSION
mvn install -DskipTests=true
