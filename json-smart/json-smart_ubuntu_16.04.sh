# ----------------------------------------------------------------------------
#
# Package	: json-smart
# Version	: 2.2
# Source repo	: https://github.com/netplex/json-smart-v2
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y wget git openjdk-8-jdk openjdk-8-jre

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

wget http://archive.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
tar -zxf apache-maven-3.3.3-bin.tar.gz
sudo  cp -R apache-maven-3.3.3 /usr/local
sudo ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/bin/mvn

# Set correct locale.
sudo touch /etc/default/locale
sudo chmod a+w /etc/default/locale
echo "LC_CTYPE=\"en_US.UTF-8\"" >> /etc/default/locale
echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale
echo "LANG=\"en_US.UTF-8\"" >> /etc/default/locale
sudo locale-gen en_US en_US.UTF-8
sudo dpkg-reconfigure --frontend=noninteractive locales

export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"
export LC_ALL="en_US.UTF-8"

# Build and test code.
git clone https://github.com/netplex/json-smart-v2
cd json-smart-v2/json-smart
sudo mvn install
mvn test
