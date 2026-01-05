#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	: quarkus
# Version	: 3.26.3
# Source repo	: https://github.com/quarkusio/quarkus
# Tested on	: UBI:9.6
# Language      : java
# Ci-Check     : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Karanam Santhosh <karanam.santhosh@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -ex

PACKAGE_NAME=quarkus
PACKAGE_URL=https://github.com/quarkusio/quarkus.git
PACKAGE_VERSION=${1:-main}
 
# Install dependencies
echo "Installing dependencies..."
yum install -y git wget unzip maven java-21-openjdk java-21-openjdk-devel

# Set up Java environment
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH
 
echo "Cloning repository..."
git clone $PACKAGE_URL
 
cd $PACKAGE_NAME
echo "Checking out version: $PACKAGE_VERSION"
git checkout $PACKAGE_VERSION
 
# Build the package
echo "Building the package..."
if ! ./mvnw --settings .github/mvn-settings.xml -B -Dscan=false -Dno-build-cache -Dgradle.cache.local.enabled=false -Dgradle.cache.remote.enabled=false -Prelease -DskipTests -DskipITs -Ddokka -Dno-test-modules -Dgpg.skip clean install | tee build-quarkus.log; then
    echo "------------------$PACKAGE_NAME: Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME: Build_success---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Build_Success"
    exit 0
fi

# Tests are skipped as it takes longer hours than are allowed
