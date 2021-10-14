# ----------------------------------------------------------------------------
#
# Package         : digraph-parser
# Version         : v1.0
# Source repo     : https://github.com/paypal/digraph-parser.git
# Tested on       : rhel 8.4
# Script License  : BSD 3-Clause License
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
#
# Java version 8 or later must be installed.
#
# ----------------------------------------------------------------------------

# variables
PKG_NAME="digraph-parser"
PKG_VERSION=v1.0
REPOSITORY="https://github.com/paypal/digraph-parser.git"

echo "Usage: $0 [r<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is r1.3.2"

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

mvn clean install | tee $LOGS_DIRECTORY/$PKG_NAME.txt

#mvn clean install -DskipTests| tee $LOGS_DIRECTORY/$PKG_NAME-mvn.txt
