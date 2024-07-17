#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : hdrhistogram
# Version       : HdrHistogram-2.1.12
# Source repo   : https://github.com/HdrHistogram/HdrHistogram.git
# Tested on     : UBI 9.3
# Language      : Java, HTML, Shell
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratibh Goshi<pratibh.goshi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=HdrHistogram
PACKAGE_VERSION=${1:-HdrHistogram-2.1.12}
PACKAGE_URL=https://github.com/HdrHistogram/HdrHistogram.git

# install tools and dependent packages
yum install -y git wget

# setup java environment
yum install -y java java-devel

export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)') 
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin

# install maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.8}
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven

export M2_HOME=/usr/local/maven

# update the path env. variable
export PATH=$PATH:$M2_HOME/bin


# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build and Test
mvn test -B --file pom.xml
if [ $? != 0 ]
then
  echo "Build and Test failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
exit 0
