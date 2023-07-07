#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 7.2.1
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
ELASTICSEARCH_VERSION=7.2.1

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
echo "network.host: localhost" >>  distribution/src/config/elasticsearch.yml
sed -i '$ a\'"buildDeb.enabled=false \n buildOssDeb.enabled=false" ./distribution/packages/build.gradle
sed -i -e "s/import java.nio.file.Path/import java.nio.file.Path\n\/\/ Detecting the architecture\n String arch = System.getProperty('os.arch', '');/g" -e "s/archiveClassifier = 'linux-x86_64'/archiveClassifier = 'linux-'+ arch/g" distribution/archives/build.gradle
sed -i -e "s/apply plugin: 'elasticsearch.test.fixtures'/apply plugin: 'elasticsearch.test.fixtures'\n\/\/ Detecting the architecture\nString arch = System.getProperty('os.arch', '');/g" -e "s/final String classifier = 'linux-x86_64'/final String classifier = 'linux-' + arch/g" distribution/docker/build.gradle
sed -i 's/if (project.file("\/proc\/cpuinfo").exists()) {/if ("ppc64le".equals(System.getProperty("os.arch"))) { \n  \/\/ Ask ppc64le to count physical CPUs for us \n ByteArrayOutputStream stdout = new ByteArrayOutputStream(); \n \t project.exec{  \n\t executable "nproc" \n\t args "--all\"  \n\t standardOutput = stdout\n}\n return Integer.parseInt(stdout.toString("UTF-8").trim())\n } else if (project.file("\/proc\/cpuinfo").exists()) {/g' buildSrc/src/main/groovy/org/elasticsearch/gradle/BuildPlugin.groovy
./gradlew assemble --refresh-dependencies

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
