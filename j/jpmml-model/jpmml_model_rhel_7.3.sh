# ----------------------------------------------------------------------------
#
# Package       : Jpmml Model
# Version       : 1.3.9
# Source repo   : https://github.com/jpmml/jpmml-model
# Tested on     : RHEL 7.3
# Language      : Java
# Travis-Check  : False 
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#! /bin/bash
sudo yum update -y
sudo yum install -y git wget tar java-1.8.0-openjdk-devel

#Install maven using tarball
wget http://apache.spinellicreations.com/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz 
tar -xvzf apache-maven-3.5.2-bin.tar.gz && rm -f $PWD/apache-maven-3.5.2-bin.tar.gz

# set the PATH to access Maven and Java
export MAVEN_HOME=$PWD/apache-maven-3.5.2
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:$MAVEN_HOME/bin:$JAVA_HOME/bin

git clone https://github.com/jpmml/jpmml-model && cd jpmml-model
mvn clean install

