#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 8.3.2
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : UBI: 8.5
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

WORKDIR=`pwd`
ELASTICSEARCH_VERSION=${1:-v8.3.2}

# install dependencies
yum install -y wget git zip unzip sudo libtool-ltdl

# install java 18
wget https://github.com/adoptium/temurin18-binaries/releases/download/jdk-18.0.1%2B10/OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz
tar -C /usr/local -xzf OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"
export JAVA_HOME=/usr/local/jdk-18.0.1+10/
export PATH=$PATH:/usr/local/jdk-18.0.1+10/bin
sudo ln -sf /usr/local/jdk-18.0.1+10/bin/java /usr/bin/
rm -f OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz

# build elasticsearch from source
git clone https://github.com/elastic/elasticsearch.git
cd elasticsearch && git checkout $ELASTICSEARCH_VERSION

# apply patch
# wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/e/elasticsearch/elasticsearch_v8.3.2.patch
wget https://raw.githubusercontent.com/vishakadesai/build-scripts/es832/e/elasticsearch/elasticsearch_v8.3.2.patch
git apply elasticsearch_v8.3.2.patch

sed -i 's/openjdk/adoptium/' build-tools-internal/version.properties
sed -i 's/18.0.1.*/18.0.1+10/' build-tools-internal/version.properties
sed -i 's/18.0.2.*/18.0.2+9/' build-tools-internal/version.properties

mkdir -p distribution/archives/linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/linux-ppc64le-tar/build.gradle
mkdir -p distribution/archives/oss-linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/oss-linux-ppc64le-tar/build.gradle

./gradlew :distribution:archives:linux-ppc64le-tar:assemble --parallel