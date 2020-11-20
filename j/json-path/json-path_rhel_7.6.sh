# ----------------------------------------------------------------------------
#
# Package			: json-path
# Version			: master (commit id #1ed1ea0)
# Source repo		: https://github.com/json-path/JsonPath
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

# install gradle 
GRADLE_VERSION=6.2.2
wget https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip
mkdir -p usr/local/gradle
unzip -d /usr/local/gradle gradle-$GRADLE_VERSION-bin.zip
ls usr/local/gradle/gradle-$GRADLE_VERSION/
rm gradle-$GRADLE_VERSION-bin.zip
export GRADLE_HOME=/usr/local/gradle
# update the path env. variable 
export PATH=$PATH:$GRADLE_HOME/gradle-$GRADLE_VERSION/bin

# create folder for saving logs 
mkdir -p /logs

# variables
PKG_NAME="json-path"
PKG_VERSION=2.4.0
LOGS_DIRECTORY=/logs
LOCAL_DIRECTORY=/root
REPOSITORY="https://github.com/json-path/JsonPath.git"

# clone, build and test specified version
#cd $LOCAL_DIRECTORY
#git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
#cd $PKG_NAME-$PKG_VERSION/
#git checkout -b $PKG_VERSION tags/$PKG_NAME-$PKG_VERSION
#./gradlew build | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION.txt

# clone, build and test master
cd $LOCAL_DIRECTORY
git clone $REPOSITORY $PKG_NAME-master
cd $PKG_NAME-master/
git checkout 1ed1ea0
./gradlew build | tee $LOGS_DIRECTORY/$PKG_NAME.txt
