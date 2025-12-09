#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : geoserver
# Version       : 2.25.3
# Source repo   : https://github.com/geoserver/geoserver
# Tested on     : UBI: 9.3
# Language      : Java
# Ci-Check  : True
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
PACKAGE_NAME=geoserver
PACKAGE_URL=https://github.com/geoserver/geoserver
PACKAGE_VERSION=${1:-"2.25.3"}

export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# install tools and dependent packages
yum install -y git wget java-17-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)')
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
cd src


# Build package
if !(mvn clean install -DskipTests); then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi


# Run test cases
if !(mvn verify); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
