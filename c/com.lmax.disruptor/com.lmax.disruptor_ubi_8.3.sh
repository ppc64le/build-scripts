# ----------------------------------------------------------------------------
#
# Package       : com.lmax.disruptor
# Version       : 3.4.4
# Source repo   : https://github.com/LMAX-Exchange/disruptor
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Variables
REPO=https://github.com/LMAX-Exchange/disruptor

# Default tag for com.lmax.disruptor
if [ -z "$1" ]; then
  export VERSION="3.4.4"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git wget unzip

# install java
yum install -y java-11-openjdk-devel

# install gradle
wget https://services.gradle.org/distributions/gradle-7.1.1-bin.zip
unzip gradle-7.1.1-bin.zip
mkdir /opt/gradle
cp -pr gradle-7.1.1/* /opt/gradle
export PATH=/opt/gradle/bin:${PATH}

#Cloning Repo
git clone $REPO
cd ./disruptor
git checkout ${VERSION}

#Build and test package
./gradlew build
./gradlew test

