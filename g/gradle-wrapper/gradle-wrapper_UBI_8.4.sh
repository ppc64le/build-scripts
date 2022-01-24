# ----------------------------------------------------------------------------
#
# Package		: gradle-wrapper
# Version		: v4.10.3/ v5.6.0
# Source repo		: https://github.com/gradle/gradle.git
# Tested on		: UBI 8.4
# Script License	: Apache License 2.0
# Maintainer		: Manik Fulpagar <manik.fulpagar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#			  
# ----------------------------------------------------------------------------

#Note: Version upgraded from v4.10.3 to v5.6.0

#!/bin/bash

# variables
PKG_NAME="gradle-wrapper"
PKG_VERSION=v5.6.0
REPOSITORY="https://github.com/gradle/gradle.git"

echo "Usage: $0 [<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is v5.6.0"

PKG_VERSION="${1:-$PKG_VERSION}"

# install tools and dependent packages
yum -y update
yum install -y git wget curl unzip nano vim make dos2unix
   
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
git branch

ls

#./gradlew <task>
./gradlew wrapper | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION.txt

#./gradlew install -Pgradle_installPath=/usr/local/gradle-source-build
#./gradlew sanitycheck
