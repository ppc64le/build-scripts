# ----------------------------------------------------------------------------
#
# Package         : Morphia-Core
# Version         : 1.6.1
# Source repo     : https://github.com/MorphiaOrg/morphia.git
# Tested on       : UBI 8
# Script License  : Apache License 2.0
# Maintainer      : Manik Fulpagar <Manik.Fulpagar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# ----------------------------------------------------------------------------
# Prerequisites:
#
# MongoDB running on port 27017
#
# Java version 8 or later must be installed.
#
# ----------------------------------------------------------------------------

# variables
PKG_NAME="Morphia-Core"
PKG_VERSION=r1.6.1
PKG_VERSION_LATEST=r2.1.7
REPOSITORY="https://github.com/MorphiaOrg/morphia.git"

echo "Usage: $0 [r<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is r1.6.1"

PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
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

#clone and build 
cd $LOCAL_DIRECTORY
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout $PKG_VERSION

mvn clean install | tee $LOGS_DIRECTORY/$PKG_NAME.txt

#mvn clean install -DskipTests| tee $LOGS_DIRECTORY/$PKG_NAME-mvn.txt
