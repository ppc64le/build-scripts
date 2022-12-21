#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package	: jackson-annotations
# Version	: 2.14.1
# Source repo	: https://github.com/FasterXML/jackson-annotations.git
# Tested on	: UBI 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Nikhil Kalbande <nkalbande@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="jackson-annotations"
PACKAGE_VERSION=2.14.1
PACKAGE_URL="https://github.com/FasterXML/jackson-annotations"

# install tools and dependent packages
yum install -y git wget

# setup java environment
yum install -y java java-devel

export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)') 
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin

# install maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.5}
wget http://mirrors.estointernet.in/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

ls /usr/local
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
ls /usr/local
rm apache-maven-$MAVEN_VERSION-bin.tar.gz
export M2_HOME=/usr/local/maven

# update the path env. variable
export PATH=$PATH:$M2_HOME/bin

# create folder for saving logs
mkdir -p /logs

# variables
LOGS_DIRECTORY=/logs
LOCAL_DIRECTORY=/root
REPOSITORY="https://github.com/FasterXML/jackson-annotations.git"

# clone, build and test specified version
cd $LOCAL_DIRECTORY
git clone $REPOSITORY $PACKAGE_NAME-$PACKAGE_VERSION
cd $PACKAGE_NAME-$PACKAGE_VERSION/
git checkout -b $PACKAGE_VERSION tags/$PACKAGE_NAME-$PACKAGE_VERSION
mvn clean install | tee $LOGS_DIRECTORY/$PACKAGE_NAME-$PACKAGE_VERSION.txt
