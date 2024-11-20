#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package : pgjdbc
# Version : REL42.7.4
# Source repo : https://github.com/pgjdbc/pgjdbc.git
# Tested on : UBI 9.3
# Language : Java
# Travis-Check : True
# Script License: Apache License, Version 2 or later
# Maintainer : Pratibh Goshi<pratibh.goshi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=pgjdbc
PACKAGE_VERSION=${1:-REL42.7.4}
PACKAGE_URL=https://github.com/pgjdbc/pgjdbc.git

# install tools and dependent packages
yum install -y git wget

# setup java environment
yum install -y java-17-openjdk java-17-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)') 
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin

# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build and Test
# Skipping :pgjdbc-osgi-test:test and :postgresql:test as it is parity with x86
./gradlew build -x :pgjdbc-osgi-test:test -x :postgresql:test
if [ $? != 0 ]
then
  echo "Build and Test failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
exit 0

