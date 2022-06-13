#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 6.7.2
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : rhel 7.6
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
ELASTICSEARCH_VERSION=6.7.2

# install dependencies
yum update -y && yum install -y maven wget git zip unzip sudo
cd $WORKDIR


# install java 12
wget https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk-12.0.2%2B10/OpenJDK12U-jdk_ppc64le_linux_hotspot_12.0.2_10.tar.gz
tar -C /usr/local -xzf OpenJDK12U-jdk_ppc64le_linux_hotspot_12.0.2_10.tar.gz
export JAVA_HOME=/usr/local/jdk-12.0.2+10
export JAVA12_HOME=/usr/local/jdk-12.0.2+10
export PATH=/usr/local/jdk-12.0.2+10/bin:$PATH
sudo ln -sf /usr/local/jdk-12.0.2+10/bin/java /usr/bin/


# build elasticsearch from source
cd $WORKDIR
git clone https://github.com/elastic/elasticsearch.git 
cd elasticsearch && git checkout v$ELASTICSEARCH_VERSION  
sed -i '/ARCHITECTURES = Collections.unmodifiableMap(m);/ i \ \ \ \ \ \ \ \ m.put("ppc64le", new Arch(0xC0000015, 0xFFFFFFFF, 2, 189, 11, 362, 358));' server/src/main/java/org/elasticsearch/bootstrap/SystemCallFilter.java 
sed -i '$ d' distribution/src/config/jvm.options 
echo "xpack.ml.enabled: false" >> distribution/src/config/elasticsearch.yml 
echo "network.host: 0.0.0.0" >>  distribution/src/config/elasticsearch.yml 
sed -i '$ a\'"buildDeb.enabled=false \n buildOssDeb.enabled=false" ./distribution/packages/build.gradle
./gradlew assemble --refresh-dependencies


# copy tar file and delete source code
tar -C /usr/share/ -xf distribution/archives/tar/build/distributions/elasticsearch-$ELASTICSEARCH_VERSION-SNAPSHOT.tar.gz
mkdir /usr/share/elasticsearch/
mv /usr/share/elasticsearch-$ELASTICSEARCH_VERSION-SNAPSHOT/* /usr/share/elasticsearch/


# add elasticsearch user 
groupadd elasticsearch && useradd elasticsearch -g elasticsearch
chown elasticsearch:elasticsearch -R /usr/share/elasticsearch


# command to start elasticsearch
# sudo -u elasticsearch /usr/share/elasticsearch/bin/elasticsearch &

# NOTE: if you are facing issues with elasticsearch startup follow these steps after isntallation
# wget https://repo1.maven.org/maven2/net/java/dev/jna/jna/4.5.1/jna-4.5.1.jar
# mv jna-4.5.1.jar /usr/share/elasticsearch/lib/
