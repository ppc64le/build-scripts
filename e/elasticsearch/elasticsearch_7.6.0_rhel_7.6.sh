#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 7.6.0
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : rhel 7.6
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

WORKDIR=$1
ELASTICSEARCH_VERSION=7.6.0

# install dependencies
yum update -y && yum install -y maven wget git zip unzip sudo libtool-ltdl docker
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
sed -i '/ARCHITECTURES = Collections.unmodifiableMap(m);/ i \ \ \ \ \ \ \ \ m.put("ppc64le", new Arch(0xC0000015, 0xFFFFFFFF, 2, 189, 11, 362, 358));' server/src/main/java/org/elasticsearch/bootstrap/SystemCallFilter.java
sed -i '$ d' distribution/src/config/jvm.options
echo "xpack.ml.enabled: false" >> distribution/src/config/elasticsearch.yml
echo "network.host: localhost" >>  distribution/src/config/elasticsearch.yml
sed -i '$ a\'"buildDeb.enabled=false \n buildOssDeb.enabled=false" ./distribution/packages/build.gradle
sed -i -e "s/import java.nio.file.Path/import java.nio.file.Path\n\/\/ Detecting the architecture\n String arch = System.getProperty('os.arch', '');/g" -e "s/archiveClassifier = 'linux-x86_64'/archiveClassifier = 'linux-'+ arch/g" distribution/archives/build.gradle
sed -i -e "s/apply plugin: 'elasticsearch.test.fixtures'/apply plugin: 'elasticsearch.test.fixtures'\n\/\/ Detecting the architecture\nString arch = System.getProperty('os.arch', '');/g" -e "s/final String classifier = 'linux-x86_64'/final String classifier = 'linux-' + arch/g" distribution/docker/build.gradle
sed -i 's/if (project.file("\/proc\/cpuinfo").exists()) {/if ("ppc64le".equals(System.getProperty("os.arch"))) { \n  \/\/ Ask ppc64le to count physical CPUs for us \n ByteArrayOutputStream stdout = new ByteArrayOutputStream(); \n \t project.exec{  \n\t executable "nproc" \n\t args "--all\"  \n\t standardOutput = stdout\n}\n return Integer.parseInt(stdout.toString("UTF-8").trim())\n } else if (project.file("\/proc\/cpuinfo").exists()) {/g' buildSrc/src/main/groovy/org/elasticsearch/gradle/BuildPlugin.groovy
./gradlew -p distribution/archives/linux-tar assemble --parallel

# copy tar file and delete source code
tar -C /usr/share/ -xf distribution/archives/linux-tar/build/distributions/elasticsearch-$ELASTICSEARCH_VERSION*-SNAPSHOT-*.tar.gz
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
