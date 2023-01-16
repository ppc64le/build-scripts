#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : jackson-databind
# Version       : jackson-databind-2.14.1
# Source repo   : https://github.com/FasterXML/jackson-databind
# Tested on     : ubi 8.5
# Travis-Check  : True
# Language      : java
# Script License: Apache License 2.0
# Maintainer    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


# Variables.
PACKAGE_NAME=jackson-databind
PACKAGE_VERSION=jackson-databind-2.14.1
PACKAGE_VERSION=${1:-$PACKAGE_VERSION}
PACKAGE_URL=https://github.com/FasterXML/jackson-databind

# For rerunning build
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
fi

# Install required dependencies
#yum -y update
yum install git maven java-11-openjdk-devel -y  
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.17.0.8-2.el8_6.ppc64le
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin

# Cloning the repository from remote to local. 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build and test
if !$(mvn clean install -DskipTests) 
then
  echo "Failed to build the package"
  exit 1
fi

if !$(mvn install) 
then
  echo "Failed to validate the package"
  exit 2
fi
