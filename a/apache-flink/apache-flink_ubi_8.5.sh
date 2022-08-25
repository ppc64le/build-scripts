#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : apache-flink
# Version       : master
# Source repo   : https://github.com/apache/flink.git
# Tested on     : UBI: 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=apache-flink
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/apache/flink.git

MAVEN_VERSION=3.5.4

# Install dependencies and tools.
yum install -y sudo
sudo yum update -y
sudo yum install -y git wget java-1.8.0-openjdk-devel xz
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# Install postgresql build dependencies
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install -y postgresql10-libs
sudo yum install -y postgresql10 postgresql10-server postgresql10-contrib

# Install maven package
wget https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz

# Set ENV variables
export M2_HOME=`pwd`/apache-maven-${MAVEN_VERSION}
export PATH=`pwd`/apache-maven-${MAVEN_VERSION}/bin:${PATH}

# Clone and build source
git clone $PACKAGE_URL
cd flink
git checkout $PACKAGE_VERSION

# Compile and build package using threads
mvn clean package -DskipTests -Pskip-webui-build
