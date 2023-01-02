#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: parquet-format
# Version	: apache-parquet-format-2.9.0
# Source repo	: https://github.com/apache/parquet-format
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
PACKAGE_NAME=parquet-format
PACKAGE_VERSION=apache-parquet-format-2.9.0
PACKAGE_URL=https://github.com/apache/parquet-format.git
WORKDIR=`pwd`

#Install required dependencies
yum install -y git make wget gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless maven

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#install protobuf compiler
wget https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz 
tar -xvzf protobuf-2.6.1.tar.gz --no-same-owner
rm -f protobuf-2.6.1.tar.gz
cd protobuf-2.6.1/
./configure
make
make install


#install thrift
wget -nv http://archive.apache.org/dist/thrift/0.13.0/thrift-0.13.0.tar.gz
tar -xzvf thrift-0.13.0.tar.gz --no-same-owner
cd thrift-0.13.0
chmod +x ./configure
./configure --disable-libs
make install

#Clone the top-level repository
cd $WORKDIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION 

#Install build tools

mvn install --batch-mode -DskipTests=true -Dmaven.javadoc.skip=true -Dsource.skip=true -Djava.version=11


