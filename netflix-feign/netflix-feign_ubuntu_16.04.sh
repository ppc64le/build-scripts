# ----------------------------------------------------------------------------
#
# Package	: netflix-feign
# Version	: 8.18.0
# Source repo	: https://github.com/Netflix/feign.git
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
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gcc g++ make \
     autoconf ruby couchdb-bin libffi6 libffi-dev build-essential \
     gettext subversion maven libtool wget git

# Install ant.
wget http://archive.apache.org/dist/ant/binaries/apache-ant-1.9.6-bin.tar.gz
tar -xvzf apache-ant-1.9.6-bin.tar.gz
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin:$PWD/apache-ant-1.9.6/bin

# Set locale required by Java.
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
sudo update-locale

# Install JNA.
git clone https://github.com/java-native-access/jna
cd jna && ant && sudo ant install
cd

# Clone and build the source code.
git clone https://github.com/Netflix/feign.git
cd feign
./mvnw install -DskipTests=true
./mvnw test
