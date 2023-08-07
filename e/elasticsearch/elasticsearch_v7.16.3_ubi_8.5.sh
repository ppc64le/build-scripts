#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 7.16.3
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : UBI-8.5
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

WORKDIR=`pwd`
ELASTICSEARCH_VERSION=${1:-v7.16.3}

yum install -y curl git gzip tar wget patch make gcc gcc-c++

yum install -y java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
export LANG="en_US.UTF-8"
export ES_JAVA_HOME=$JAVA_HOME
export JAVA17_HOME=$JAVA_HOME


# build elasticsearch from source
git clone https://github.com/elastic/elasticsearch.git
cd elasticsearch && git checkout $ELASTICSEARCH_VERSION
# Apply patches
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/e/elasticsearch/elasticsearch_v7.16.3.patch
git apply elasticsearch_v7.16.3.patch
mkdir -p distribution/archives/linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/linux-ppc64le-tar/build.gradle
mkdir -p distribution/archives/oss-linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/oss-linux-ppc64le-tar/build.gradle

./gradlew :distribution:archives:linux-ppc64le-tar:assemble --parallel
