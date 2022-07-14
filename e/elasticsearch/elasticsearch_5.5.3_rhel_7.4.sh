#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 5.5.3
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : rhel_7.4
# Travis-Check  : True
# Language      : Java
# Script License: Apache License, Version 2 or later
# Maintainer    : Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

export ELASTICSEARCH_VERSION=5.5.3

#Install Dependencies
yum install -y sudo
sudo yum -y update 
sudo yum -y install maven git wget tar zip unzip java-1.8.0-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
 
#Install Gradle
sudo mkdir /opt/gradle 
wget https://services.gradle.org/distributions/gradle-3.4.1-bin.zip
sudo unzip -d /opt/gradle gradle-3.4.1-bin.zip
export PATH=/opt/gradle/gradle-3.4.1/bin:$PATH

#Get Elasticsearch Source
git clone https://github.com/elastic/elasticsearch.git
cd elasticsearch && git checkout v$ELASTICSEARCH_VERSION

#Set Locales
sudo localedef -v -c -i en_US -f UTF-8 en_US.UTF-8
export LC_ALL=en_US.UTF-8

#Build
gradle assemble --refresh-dependencies

#Test
#NOTE: 2 tests will fail with default JNA, as the default JNA does not come with ppc64le support. Also these tests have a dependency on version 4.4.0-1 of JNA.

gradle test


