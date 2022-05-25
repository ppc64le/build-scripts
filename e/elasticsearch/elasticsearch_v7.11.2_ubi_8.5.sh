#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : v7.11.2
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : UBI-8.5
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Kandarpa Malipeddi <kandarpa.malipeddi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

WORKDIR=`pwd`
ELASTICSEARCH_VERSION=${1:-v7.11.2}

# install dependencies
yum update -y && yum install -y wget git zip unzip sudo libtool-ltdl

# install java 15
wget https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/jdk15u-2021-01-22-02-31/OpenJDK15U-jdk_ppc64le_linux_hotspot_2021-01-22-02-31.tar.gz && \
tar -C /usr/local -xzf OpenJDK15U-jdk_ppc64le_linux_hotspot_2021-01-22-02-31.tar.gz &&\
export JAVA_HOME=/usr/local/jdk-15.0.2+7/ && \
export JAVA15_HOME=/usr/local/jdk-15.0.2+7/ && \
export PATH=$PATH:/usr/local/jdk-15.0.2+7/bin && \
ln -sf /usr/local/jdk-15.0.2+7/bin/java /usr/bin/ && \
rm -f OpenJDK15U-jdk_ppc64le_linux_hotspot_2021-01-22-02-31.tar.gz


# build elasticsearch from source
git clone https://github.com/elastic/elasticsearch.git
cd elasticsearch && git checkout $ELASTICSEARCH_VERSION
# Apply patches
wget https://raw.githubusercontent.com/kandarpamalipeddi/build-scripts/master/e/elasticsearch/elasticsearch_7.11.2.patch
git apply elasticsearch_7.11.2.patch
mkdir -p distribution/archives/linux-ppc64le-tar

./gradlew :distribution:archives:linux-ppc64le-tar:assemble --parallel