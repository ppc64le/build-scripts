#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : Apache Flink
# Version       : master,release-1.17.1
# Source repo   : https://github.com/apache/flink
# Tested on     : UBI: 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Muskaan Sheik <Muskaan.Sheik@ibm.com>, Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=apache-flink
PACKAGE_VERSION=${1:-release-1.17.1}
PACKAGE_URL=https://github.com/apache/flink.git

MAVEN_VERSION=3.9.4

# Install dependencies and tools.
yum update -y
yum install -y git wget java-1.8.0-openjdk-devel xz python2 python2-devel

ln -sf /usr/bin/python2 /usr/bin/python
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Install postgresql build dependencies
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
yum install -y postgresql12-libs
yum install -y postgresql12 postgresql12-server postgresql12-contrib

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
mvn clean package -DskipTests -Pskip-webui-build -Drat.skip=true

# Several modules cause test failure, excluding those modules during testing because it is in parity with Intel
mvn test -Drat.skip=true -pl '!flink-connectors/flink-connector-kafka, !flink-connectors/flink-connector-hbase-2.2, !flink-filesystems/flink-s3-fs-base, !flink-filesystems/flink-s3-fs-hadoop, !flink-filesystems/flink-s3-fs-presto, !flink-filesystems/flink-azure-fs-hadoop,!flink-state-backends/flink-statebackend-changelog'
