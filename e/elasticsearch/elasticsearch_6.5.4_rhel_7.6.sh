#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 6.5.4
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : rhel 7.6
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Lysanne Fernandes <lysannef@us.ibm.com>
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
yum update -y && yum install -y maven wget git zip unzip sudo java-11-openjdk-devel.ppc64le
cd $WORKDIR


# configure openjdk11
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.4.11-0.el7_6.ppc64le
export PATH=$PATH:$JAVA_HOME/bin
alternatives --set java /usr/lib/jvm/java-11-openjdk-11.0.4.11-0.el7_6.ppc64le/bin/java

#Install Gradle
sudo mkdir /opt/gradle
wget https://services.gradle.org/distributions/gradle-4.10.3-bin.zip
sudo unzip -d /opt/gradle gradle-4.10.3-bin.zip
export PATH=/opt/gradle/gradle-4.10.3/bin:$PATH


# build elasticsearch from source
cd $WORKDIR
git clone https://github.com/crate/elasticsearch.git 
cd elasticsearch && git checkout v$ELASTICSEARCH_VERSION  
sed -i '/ARCHITECTURES = Collections.unmodifiableMap(m);/ i \ \ \ \ \ \ \ \ m.put("ppc64le", new Arch(0xC0000015, 0xFFFFFFFF, 2, 189, 11, 362, 358));' server/src/main/java/org/elasticsearch/bootstrap/SystemCallFilter.java 
sed -i '$ d' distribution/src/config/jvm.options 
echo "xpack.ml.enabled: false" >> distribution/src/config/elasticsearch.yml 
echo "network.host: 0.0.0.0" >>  distribution/src/config/elasticsearch.yml 
sed -i '$ a\'"buildDeb.enabled=false \n buildOssDeb.enabled=false" ./distribution/packages/build.gradle
gradle assemble --refresh-dependencies

# copy tar file and delete source code
tar -C /usr/share/ -xf distribution/archives/tar/build/distributions/elasticsearch-$ELASTICSEARCH_VERSION-SNAPSHOT.tar.gz
mkdir /usr/share/elasticsearch/
mv /usr/share/elasticsearch-$ELASTICSEARCH_VERSION-SNAPSHOT/* /usr/share/elasticsearch/


# add elasticsearch user 
groupadd elasticsearch && useradd elasticsearch -g elasticsearch
chown elasticsearch:elasticsearch -R /usr/share/elasticsearch


# command to start elasticsearch
# sudo -u elasticsearch /usr/share/elasticsearch/bin/elasticsearch &

