# ----------------------------------------------------------------------------
#
# Package         : okhttp-ws
# Version         : parent-2.7.5
# Source repo     : https://github.com/square/okhttp.git
# Tested on       : rhel 8.4
# Script License  : Apache-2.0 License
# Maintainer      : Manik Fulpagar <Manik.Fulpagar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#		
# ----------------------------------------------------------------------------

# Note : For this package 4 modules are failing tests, are in parity with intel

#!/bin/bash

# ----------------------------------------------------------------------------
# Prerequisites:
#
#Java-11
# 
# ----------------------------------------------------------------------------

# variables
PKG_NAME="okhttp-ws"
PKG_VERSION=parent-2.7.5
REPOSITORY="https://github.com/square/okhttp.git"

echo "Usage: $0 [r<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is parent-2.7.5"

PKG_VERSION="${1:-$PKG_VERSION}"

# install tools and dependent packages
yum -y update
yum install -y git wget curl unzip nano vim make diffutils

#install maven
yum install -y maven

# setup java environment
yum install -y java-11 java-devel

which java
ls /usr/lib/jvm/
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
echo "JAVA_HOME is $JAVA_HOME"
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin

# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

LOCAL_DIRECTORY=/root

# clone, build and test latest version
cd $LOCAL_DIRECTORY
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/

git checkout $PKG_VERSION

#mvn clean verify -fn | tee $LOGS_DIRECTORY/$PKG_NAME.txt

mvn clean install -DskipTests| tee $LOGS_DIRECTORY/$PKG_NAME-withoutTest.txt