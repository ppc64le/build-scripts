#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opencsv
# Version       : 5.9Release
# Source repo   : https://git.code.sf.net/p/opencsv/source
# Tested on     : UBI 9.5 (ppc64le)
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=opencsv
PACKAGE_VERSION=${1:-5.9Release}
PACKAGE_URL=https://git.code.sf.net/p/${PACKAGE_NAME}/source.git
BUILD_HOME=$(pwd)
MAVEN_VERSION=3.9.6

# -------------------------
# Environment Setup
# -------------------------
yum install -y git wget java-11-openjdk-devel

# Setting up Java environment...
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
export PATH="$JAVA_HOME/bin:$PATH"

# Installing Maven
cd /opt
wget -q https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
ln -s apache-maven-${MAVEN_VERSION} maven
export MAVEN_HOME="/opt/maven"
export PATH="${MAVEN_HOME}/bin:$PATH"
rm -f apache-maven-${MAVEN_VERSION}-bin.tar.gz

# -------------------------
# Clone Repository
# -------------------------
cd "$BUILD_HOME"
git clone "$PACKAGE_URL" "$PACKAGE_NAME"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

# -------------------------
# Build
# -------------------------
ret=0
mvn clean install -Dgpg.skip=true -DskipTests || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "[ERROR] $PACKAGE_NAME - Build failed."
    exit 1
else
    echo "[SUCCESS] $PACKAGE_NAME - Build completed successfully."
fi

# -------------------------
# Test
# -------------------------
mvn test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "[ERROR] $PACKAGE_NAME - Tests failed."
    exit 2
else
    echo "[SUCCESS] $PACKAGE_NAME - All tests passed successfully."
fi

echo "[PASS] ${PACKAGE_NAME}_${PACKAGE_VERSION} Build and Test successful."
exit 0
