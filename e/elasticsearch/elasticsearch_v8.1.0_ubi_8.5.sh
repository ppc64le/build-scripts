# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 8.1.0
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
#!/bin/bash -ex

WORKDIR=`pwd`
ELASTICSEARCH_VERSION=${1:-v8.1.0}

# install dependencies
yum update -y && yum install -y wget git zip unzip sudo libtool-ltdl docker
cd $WORKDIR


# install java 13
wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.2%2B8/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.2_8.tar.gz && \
tar -C /usr/local -xzf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.2_8.tar.gz
export JAVA_HOME=/usr/local/jdk-17.0.2+8/
export JAVA17_HOME=/usr/local/jdk-17.0.2+8/
export PATH=$PATH:/usr/local/jdk-17.0.2+8/bin
sudo ln -sf /usr/local/jdk-17.0.2+8/bin/java /usr/bin/
rm -f OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.2_8.tar.gz


# build elasticsearch from source
cd $WORKDIR
git clone https://github.com/elastic/elasticsearch.git
cd elasticsearch && git checkout $ELASTICSEARCH_VERSION
# Apply patches
wget https://raw.githubusercontent.com/kandarpamalipeddi/build-scripts/master/e/elasticsearch/elasticsearch_v8.1.0.patch
git apply elasticsearch_v8.1.0.patch
mkdir -p distribution/archives/linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/linux-ppc64le-tar/build.gradle
mkdir -p distribution/archives/oss-linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/oss-linux-ppc64le-tar/build.gradle

./gradlew :distribution:archives:oss-linux-ppc64le-tar:assemble --parallel
