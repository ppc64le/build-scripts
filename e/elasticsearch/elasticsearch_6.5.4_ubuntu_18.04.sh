#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 6.5.4
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : ubuntu_18.04
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Shivani Junawane <shivanij@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


WORKDIR=$1
ELASTICSEARCH_VERSION=6.5.4

# install dependencies
apt-get update -y && apt-get install -y maven wget git zip unzip sudo
cd $WORKDIR


# install openjdk11
wget https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11%2B28/OpenJDK11-jdk_ppc64le_linux_hotspot_11_28.tar.gz 
tar -C /usr/share/ -xzvf OpenJDK11-jdk_ppc64le_linux_hotspot_11_28.tar.gz 
rm -rf OpenJDK11-jdk_ppc64le_linux_hotspot_11_28.tar.gz 
export JAVA_HOME=/usr/share/jdk-11+28
export PATH=$JAVA_HOME:$PATH


# build elasticsearch from source
git clone https://github.com/crate/elasticsearch.git 
cd elasticsearch && git checkout v$ELASTICSEARCH_VERSION  
sed -i '/ARCHITECTURES = Collections.unmodifiableMap(m);/ i \ \ \ \ \ \ \ \ m.put("ppc64le", new Arch(0xC0000015, 0xFFFFFFFF, 2, 189, 11, 362, 358));' server/src/main/java/org/elasticsearch/bootstrap/SystemCallFilter.java 
sed -i '$ d' distribution/src/config/jvm.options 
echo "xpack.ml.enabled: false" >> distribution/src/config/elasticsearch.yml 
echo "network.host: 0.0.0.0" >>  distribution/src/config/elasticsearch.yml 
./gradlew assemble --refresh-dependencies


# copy tar file and delete source code
tar -C /usr/share/ -xf distribution/archives/tar/build/distributions/elasticsearch-6.5.4-SNAPSHOT.tar.gz
mkdir /usr/share/elasticsearch/
mv /usr/share/elasticsearch-6.5.4-SNAPSHOT/* /usr/share/elasticsearch/

# explicitly download jna jar
wget https://repo1.maven.org/maven2/net/java/dev/jna/jna/4.5.1/jna-4.5.1.jar
mv jna-4.5.1.jar /usr/share/elasticsearch/lib/

# add elasticsearch user 
groupadd elasticsearch && useradd elasticsearch -g elasticsearch
chown elasticsearch:elasticsearch -R /usr/share/elasticsearch


# command to start elasticsearch
# sudo -u elasticsearch /usr/share/elasticsearch/bin/elasticsearch &
