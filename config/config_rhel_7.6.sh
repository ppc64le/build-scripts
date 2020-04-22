# ----------------------------------------------------------------------------
#
# Package			: config
# Version			: 1.3.4, 1.4.0
# Source repo		: https://github.com/lightbend/config
# Tested on			: RHEL 7.6
# Script License	: Apache License Version 2.0
# Maintainer		: Pratham Murkute <prathamm@us.ibm.com>
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
#yum -y update
yum install -y git wget curl unzip nano vim make build-essential dos2unix
#yum install -y gcc ant

# setup java environment
yum install -y java java-devel
which java
ls /usr/lib/jvm/
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-ibm-1.8.0.6.5-1jpp.1.el7.ppc64le
# update the path env. variable 
export PATH=$PATH:$JAVA_HOME/bin

# install sbt
curl https://bintray.com/sbt/rpm/rpm | tee /etc/yum.repos.d/bintray-sbt-rpm.repo
yum install -y sbt

# create folder for saving logs 
mkdir -p /logs

# variables
PKG_NAME="config"
PKG_VERSION=1.3.4
PKG_VERSION_LATEST=1.4.0
LOGS_DIRECTORY=/logs
LOCAL_DIRECTORY=/root
REPOSITORY="https://github.com/lightbend/config.git"

# clone, build and test specified version
cd $LOCAL_DIRECTORY
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout -b $PKG_VERSION tags/v$PKG_VERSION
sbt compile test package | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION.txt

# clone, build and test latest version
cd $LOCAL_DIRECTORY
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION_LATEST
cd $PKG_NAME-$PKG_VERSION_LATEST/
git checkout -b $PKG_VERSION_LATEST tags/v$PKG_VERSION_LATEST
sbt compile test package | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION_LATEST.txt

# clone, build and test master
#cd $LOCAL_DIRECTORY
#git clone $REPOSITORY $PKG_NAME-master
#cd $PKG_NAME-master/
#sbt compile test package | tee $LOGS_DIRECTORY/$PKG_NAME.txt
