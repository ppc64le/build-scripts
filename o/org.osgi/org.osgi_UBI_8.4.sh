# ----------------------------------------------------------------------------
#
# Package         : org.osgi
# Version         : r8-core-final-rerelease
# Source repo     : https://github.com/osgi/osgi.git
# Tested on       : rhel 8.4
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
#
# Java version 8 or later must be installed.
#
# ----------------------------------------------------------------------------

# variables
PKG_NAME="org.osgi"
PKG_VERSION=r8-core-final-rerelease
REPOSITORY="https://github.com/osgi/osgi.git"

echo "Usage: $0 [r<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is r8-core-final-rerelease"

PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
yum -y update
yum install -y git wget.ppc64le openssl-devel.ppc64le diffutils curl unzip zip cmake make gcc-c++ autoconf ncurses-devel.ppc64le

#yum install -y git wget openssl-devel diffutils curl unzip zip cmake make gcc-c++ autoconf ncurses-devel

#install java 8
yum install -y java java-devel
which java
ls /usr/lib/jvm/
# Set JAVA_HOME variable
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-1.8)(?=.*ppc64le)')
#export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-1.8)(?=.*x86_64)')
echo $JAVA_HOME
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin
echo $PATH

# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

LOCAL_DIRECTORY=/root

#clone and build 
cd $LOCAL_DIRECTORY	
git clone $REPOSITORY
cd osgi/
git checkout $PKG_VERSION

#Install Ant (Required for old version r4-core-spec-final)
#wget https://downloads.apache.org/ant/binaries/apache-ant-1.10.11-bin.tar.gz
#tar -xf apache-ant-1.10.11-bin.tar.gz
#export ANT_HOME=${HOME}/apache-ant-1.10.11/
#export PATH=${PATH}:${ANT_HOME}/bin
#which ant
#ant -version
#ant

#Build and test package
./gradlew :build | tee $LOGS_DIRECTORY/$PKG_NAME.txt
./gradlew :osgi.specs:specifications
./gradlew :org.osgi.test.cases.remoteserviceadmin:testOSGi | tee $LOGS_DIRECTORY/$PKG_NAME_test.txt