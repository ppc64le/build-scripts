#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : univocity-parsers
# Version       : v2.9.1
# Source repo   : https://github.com/univocity/univocity-parsers
# Tested on     : UBI: 8.7
# Language      : Java
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
PACKAGE_NAME=univocity-parsers
PACKAGE_URL=https://github.com/univocity/univocity-parsers

# Default tag univocity-parsers
if [ -z "$1" ]; then
  export PACKAGE_VERSION="v2.9.1"
else
  export PACKAGE_VERSION="$1"
fi

# install tools and dependent packages
yum install -y git wget
yum install -y java-1.8.0-openjdk-devel.ppc64le
export JDK8_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JDK8_HOME/bin:$PATH

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
fi

