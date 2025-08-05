#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 9.0.4
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : UBI:9.3
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Manya Rusiya<Manya.Rusiya@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=elasticsearch
PACKAGE_URL=https://github.com/elastic/elasticsearch.git
ELASTICSEARCH_VERSION=${1:-v9.0.4}
CURRENT_DIR=`pwd`
#WORKDIR=$(pwd)
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

# install dependencies
#yum update -y
yum install -y libcurl-devel git gzip tar wget patch make gcc gcc-c++ patch


wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.2%2B13/OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.2_13.tar.gz
tar -xf OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.2_13.tar.gz -C /opt
export JAVA_HOME=/opt/jdk-21.0.2+13
export PATH=$JAVA_HOME/bin:$PATH
java -version
export JAVA_HOME=/opt/jdk-21.0.2+13
export PATH=$JAVA_HOME/bin:$PATH
# ./gradlew --version


# build elasticsearch from source
git clone $PACKAGE_URL
cd $PACKAGE_NAME && git checkout $ELASTICSEARCH_VERSION


# Apply patches
git apply $SCRIPT_DIR/elasticsearch_v9.0.4.patch

mkdir -p distribution/archives/linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/linux-ppc64le-tar/build.gradle
mkdir -p distribution/archives/oss-linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/oss-linux-ppc64le-tar/build.gradle
mkdir -p distribution/archives/linux-ppc64le-tar
mkdir -p distribution/archives/no-jdk-darwin-ppc64le-tar
mkdir -p distribution/docker/ubi-docker-ppc64le-export
mkdir -p distribution/packages/ppc64le-deb
mkdir -p distribution/docker/ironbank-docker-ppc64le-export
mkdir -p distribution/docker/docker-ppc64le-export
mkdir -p distribution/packages/ppc64le-rpm
mkdir -p distribution/archives/darwin-ppc64le-tar


# skipping Java 22 and Java 23 code compilation, since we don’t have those JDKs installed.
./gradlew :distribution:archives:linux-ppc64le-tar:assemble --parallel  -x compileMain22Java   -x compileMain23Java
