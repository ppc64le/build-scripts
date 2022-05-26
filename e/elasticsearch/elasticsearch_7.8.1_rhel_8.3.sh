#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 7.8.1
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : rhel 8.3
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Sachin Kakatkar <sachin.kakatkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

WORKDIR=`pwd`
ELASTICSEARCH_VERSION=7.8.1

# install dependencies
dnf install -y maven wget git zip unzip sudo libtool-ltdl docker
cd $WORKDIR


# install java 13
wget https://github.com/AdoptOpenJDK/openjdk13-binaries/releases/download/jdk13u-2020-02-24-07-25/OpenJDK13U-jdk_ppc64le_linux_hotspot_2020-02-24-07-25.tar.gz
tar -C /usr/local -xzf OpenJDK13U-jdk_ppc64le_linux_hotspot_2020-02-24-07-25.tar.gz
export JAVA_HOME=/usr/local/jdk-13.0.2+8/
export JAVA13_HOME=/usr/local/jdk-13.0.2+8/
export PATH=$PATH:/usr/local/jdk-13.0.2+8/bin
sudo ln -sf /usr/local/jdk-13.0.2+8/bin/java /usr/bin/


# build elasticsearch from source
cd $WORKDIR
git clone https://github.com/elastic/elasticsearch.git
cd elasticsearch && git checkout v$ELASTICSEARCH_VERSION

# Apply patches
wget https://raw.githubusercontent.com/ppc64le/build-scripts/blob/master/e/elasticsearch/elasticsearch_v7.8.1.patch
git apply elasticsearch_v7.8.1.patch
mkdir -p distribution/archives/linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/linux-ppc64le-tar/build.gradle
mkdir -p distribution/archives/oss-linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/oss-linux-ppc64le-tar/build.gradle

./gradlew :distribution:archives:oss-linux-ppc64le-tar:assemble --parallel

# build docker image
./gradlew distribution:docker:assemble --parallel

#Run the tests cases of specific package
./gradlew test "-Dtests.package=org.elasticsearch.search.aggregations.matrix.stats”
./gradlew test "-Dtests.package=org.elasticsearch.script.mustache”

#Run all tests in a package and its sub-packages
./gradlew test "-Dtests.class=org.elasticsearch.package.*"

# copy tar file and delete source code
tar -C /usr/share/ -xf distribution/archives/oss-linux-ppc64le-tar/build/distributions/elasticsearch-oss-$ELASTICSEARCH_VERSION*-SNAPSHOT-*.tar.gz
mkdir /usr/share/elasticsearch/
mv /usr/share/elasticsearch-$ELASTICSEARCH_VERSION*-SNAPSHOT/* /usr/share/elasticsearch/


# add elasticsearch user 
groupadd elasticsearch && useradd elasticsearch -g elasticsearch
chown elasticsearch:elasticsearch -R /usr/share/elasticsearch

# command to start elasticsearch
#sudo -u elasticsearch /usr/share/elasticsearch/bin/elasticsearch &

# NOTE: if you are facing issues with elasticsearch startup follow these steps after isntallation
# wget https://repo1.maven.org/maven2/net/java/dev/jna/jna/4.5.1/jna-4.5.1.jar
# mv jna-4.5.1.jar /usr/share/elasticsearch/lib/
