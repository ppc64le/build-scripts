#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	    : simpleclient_common
# Version	    : parent-0.9.0
# Source repo	: https://github.com/prometheus/client_java.git
# Tested on	    : UBI 8.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Srividya Chittiboina <Srividya.Chittiboina@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

WORK_DIR=`pwd`

PACKAGE_NAME=client_java
PACKAGE_VERSION=${1:-parent-0.9.0}
PACKAGE_URL=https://github.com/prometheus/client_java.git

yum install -y git java-11-openjdk-devel maven

#clone repo
cd $WORK_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout ${PACKAGE_VERSION}

#build and test repo
mvn clean install -DskipTests
mvn test