#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package         : bcprov-jdk15on
# Version         : r1rv61, r1rv68
# Source repo     : https://github.com/bcgit/bc-java
# Tested on       : UBI: 8.3
# Language        : Java
# Travis-Check    : True
# Script License  : Apache License 2.0
# Maintainer's    : Srividya Chittiboina <Srividya.Chittiboina@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=bc-java
PACKAGE_URL=https://github.com/bcgit/bc-java
PACKAGE_VERSION="${1:-r1rv61}"

yum install -y git wget unzip
yum install -y java-1.8.0-openjdk-devel

# install gradle
wget https://downloads.gradle-dn.com/distributions/gradle-3.3-all.zip
unzip -d /opt/gradle gradle-3.3-all.zip
ls /opt/gradle/gradle-3.3/
export PATH=$PATH:/opt/gradle/gradle-3.3/bin

#Cloning Repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout ${PACKAGE_VERSION}
cd prov

#Build and test package
gradle build
gradle test 