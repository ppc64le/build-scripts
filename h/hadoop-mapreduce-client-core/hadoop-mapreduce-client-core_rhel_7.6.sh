# ----------------------------------------------------------------------------
#
# Package			: hadoop-mapreduce-client-core
# Version			: 2.6.0 (commit #5f39827)
# Source repo		: https://github.com/hdfs-mapreduce/hadoop-mapreduce-client
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

# install maven
MAVEN_VERSION=3.6.3
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
PKG_NAME="hadoop-mapreduce-client-core"
PKG_VERSION=2.6.0
PKG_VERSION_LATEST=""
LOGS_DIRECTORY=/logs
LOCAL_DIRECTORY=/root
REPOSITORY="https://github.com/hdfs-mapreduce/hadoop-mapreduce-client.git"

# clone, build and test specified version
# not available in repository
#cd $LOCAL_DIRECTORY
#git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
#cd $PKG_NAME-$PKG_VERSION/
#git checkout -b $PKG_VERSION tags/$PKG_VERSION
#mvn install | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION.txt

# clone, build and test master
cd $LOCAL_DIRECTORY
git clone $REPOSITORY $PKG_NAME-master
cd $PKG_NAME-master/
cd hadoop-mapreduce-client-core/
mvn install | tee $LOGS_DIRECTORY/$PKG_NAME.txt
