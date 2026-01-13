#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 7.17.28
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : UBI:9.6
# Ci-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Sanket Patil <Sanket.Patil11@ibm.com>
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
ELASTICSEARCH_VERSION=${1:-v7.17.28}
CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

# install dependencies
yum install -y libcurl-devel git gzip tar wget patch make gcc gcc-c++ java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
export LANG="en_US.UTF-8"
export ES_JAVA_HOME=$JAVA_HOME
export JAVA17_HOME=$JAVA_HOME

# build elasticsearch from source
git clone $PACKAGE_URL
cd $PACKAGE_NAME && git checkout $ELASTICSEARCH_VERSION

# Apply patches
git apply $SCRIPT_DIR/elasticsearch_v7.17.28.patch

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

./gradlew :distribution:archives:linux-ppc64le-tar:assemble --parallel

#Test -- run it as non - root user 
#./gradlew test -x :x-pack:plugin:ml:test --no-parallel --continue
