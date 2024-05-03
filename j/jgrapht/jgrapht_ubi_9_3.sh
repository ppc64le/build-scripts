#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : jgrapht
# Version       : jgrapht-1.5.2
# Source repo   : https://github.com/jgrapht/jgrapht
# Tested on     : UBI: 9.3
# Language      : java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
export PACKAGE_NAME=jgrapht
export PACKAGE_URL=https://github.com/jgrapht/jgrapht

#variables to handle special characters occourance 
export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# Default tag jgrapht
if [ -z "$1" ]; then
  export PACKAGE_VERSION="jgrapht-1.5.2"
else
  export PACKAGE_VERSION="$1"
fi


# install tools and dependent packages
yum install -y git wget java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

#installing maven 3.8.6
wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.6-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.6-bin.tar.gz
mv /usr/local/apache-maven-3.8.6 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
      rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Removed existing package if any"
fi

# Cloning the repository 
git clone $PACKAGE_URL
cd ${PACKAGE_NAME}
git checkout $PACKAGE_VERSION


#Build and test package
if ! mvn clean install -DskipTests; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi
if ! mvn test;then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi
