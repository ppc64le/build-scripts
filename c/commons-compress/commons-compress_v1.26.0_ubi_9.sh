#!/bin/bash -e
# ---------------------------------------------------------------------------------------------
#
# Package       : commons-compress
# Version       : 1.26.0
# Source repo	: https://github.com/apache/commons-compress.git
# Tested on     : UBI 9.3 (ppc64le)
# Language      : JavaScript, Java
# Ci-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------------------------

PACKAGE_NAME=commons-compress
PACKAGE_VERSION=${1:-rel/commons-compress-1.26.0}
PACKAGE_URL=https://github.com/apache/${PACKAGE_NAME}.git
BUILD_HOME=$(pwd)

#install system dependencies
sudo yum install -y git java-17-openjdk-devel maven glibc-langpack-en

#set JAVA_HOME dynamically
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
export PATH="$JAVA_HOME/bin:$PATH"

# Ensure UTF-8 locale is available and set
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Clone the repository
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build and test the package/library.
ret=0
mvn clean install || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "[ERROR] $PACKAGE_NAME: build failed ---------------------------------------------------------------"
    exit 1
else
    echo "[PASS] $PACKAGE_NAME: build and tests passed successfully for version: $PACKAGE_VERSION"
	exit 0
fi

