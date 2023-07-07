#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package           : apache-lucene
# Version	    : releases/lucene/9.5.0
# Source repo       : https://github.com/apache/lucene.git
# Tested on	    : ubi 8.5
# Language          : java
# Travis-Check      : true
# Script License    : Apache License, Version 2 or later
# Maintainer	    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME="lucene"
PACKAGE_VERSION=${1:-"releases/lucene/9.5.0"}
PACKAGE_URL=https://github.com/apache/lucene.git

# Install dependencies
yum install -y git wget 

# Setup java environment
wget https://github.com/adoptium/temurin19-binaries/releases/download/jdk-19.0.2%2B7/OpenJDK19U-jdk_ppc64le_linux_hotspot_19.0.2_7.tar.gz
tar -C /usr/lib/ -xzf OpenJDK19U-jdk_ppc64le_linux_hotspot_19.0.2_7.tar.gz
export JAVA_HOME=/usr/lib/jdk-19.0.2+7
# update the path env. variable 
export PATH=$PATH:$JAVA_HOME/bin

# clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Building latest release
if ! ./gradlew; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Testing latest release
if ! ./gradlew test; then
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
