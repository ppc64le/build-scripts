# ----------------------------------------------------------------------------
#
# Package       : com.lmax.disruptor
# Version       : f8d4db46f69e0da19739cbecb973a27498382984 
# Source repo   : https://github.com/LMAX-Exchange/disruptor
# Tested on     : UBI: 8.4
# Script License: Apache License 2.0
# Maintainer's  : Sapana Khemkar <Sapana.Khemkar@ibm.com>
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
PACKAGE_NAME=disruptor
PACKAGE_URL=https://github.com/LMAX-Exchange/disruptor
PACKAGE_VERSION=f8d4db46f69e0da19739cbecb973a27498382984

# install tools and dependent packages
yum install -y git 

# install java
yum install -y java-11-openjdk-devel

# install gradle
#wget https://services.gradle.org/distributions/gradle-7.1.1-bin.zip
#unzip gradle-7.1.1-bin.zip
#mkdir /opt/gradle
#cp -pr gradle-7.1.1/* /opt/gradle
#export PATH=/opt/gradle/bin:${PATH}

#Cloning Repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout ${PACKAGE_VERSION}

#Build and test package
./gradlew 

exit 0
