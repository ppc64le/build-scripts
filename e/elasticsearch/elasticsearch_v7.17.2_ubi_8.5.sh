#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 7.17.2
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : UBI-8.5
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

WORKDIR=`pwd`
ELASTICSEARCH_VERSION=${1:-v7.17.2}

# install dependencies
#yum update -y 
yum install -y wget git zip unzip sudo libtool-ltdl patch

wget https://github.com/adoptium/temurin18-binaries/releases/download/jdk-18.0.1%2B10/OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz
tar -C /usr/local -xzf OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz
export JAVA_HOME=/usr/local/jdk-18.0.1+10
export PATH=$PATH:/usr/local/jdk-18.0.1+10/bin
rm -rf OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz


# build elasticsearch from source
git clone https://github.com/elastic/elasticsearch.git
cd elasticsearch && git checkout $ELASTICSEARCH_VERSION
# Apply patches
wget https://raw.githubusercontent.com/ppc64le/build-scripts/elastic-currency/e/elasticsearch/elasticsearch_v7.17.2.patch
patch -p1 < elasticsearch_v7.17.2.patch
mkdir -p distribution/archives/linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/linux-ppc64le-tar/build.gradle
mkdir -p distribution/archives/oss-linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/oss-linux-ppc64le-tar/build.gradle

./gradlew :distribution:archives:linux-ppc64le-tar:assemble --parallel
