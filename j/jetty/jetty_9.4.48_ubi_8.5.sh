#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : jetty
# Version	    : 9.4.48
# Source repo	: https://github.com/eclipse/jetty.project.git
# Tested on	    : UBI: 8.5
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Install dependencies.
yum -y install git wget java-1.8.0-openjdk-devel.ppc64le

# Install maven.
wget https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -xvzf apache-maven-3.8.6-bin.tar.gz
cp -R apache-maven-3.8.6 /usr/local
ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# Clone and build source.
git clone https://github.com/eclipse/jetty.project.git
cd jetty.project && git checkout jetty-9.4.48.v20220622
mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V