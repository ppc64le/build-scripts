#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : jetty
# Version	    : 10.0.12, 11.0.12
# Source repo	: https://github.com/eclipse/jetty.project.git
# Tested on	    : UBI: 8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_URL=https://github.com/eclipse/jetty.project.git
PACKAGE_VERSION=${1:-jetty-11.0.12}

# Install dependencies.
yum -y install git wget java-11-openjdk-devel.ppc64le

# Install maven.
wget https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -xvzf apache-maven-3.8.6-bin.tar.gz
cp -R apache-maven-3.8.6 /usr/local
ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

# Clone and build source.
git clone $PACKAGE_URL
cd jetty.project && git checkout $PACKAGE_VERSION
mvn install -DskipTests=true

