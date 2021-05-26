# ----------------------------------------------------------------------------
#
# Package			: airline
# Version			: 0.9
# Source repo		: https://github.com/airlift/airline
# Tested on			: RHEL 7.6
# Script License	: Apache License Version 2.0
# Maintainer		: Vedang Wartikar <vedang.wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# install tools and dependent packages
yum update -y
yum install git -y

# setup java environment
yum install java java-devel -y
JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"
echo $JAVA_HOME
export PATH=$PATH:$JAVA_HOME/bin
java -version

# install maven
dnf install maven -y
mvn -version

# create folder for saving logs 
mkdir -p /logs

# variables
PKG_NAME="airline"
PKG_VERSION=0.9
PKG_VERSION_LATEST=0.9
LOGS_DIRECTORY=/logs
LOCAL_DIRECTORY=/root
REPOSITORY="https://github.com/airlift/airline.git"

# clone, build and test specified version
cd $LOCAL_DIRECTORY
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout -b $PKG_VERSION tags/$PKG_VERSION
mvn install | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION.txt