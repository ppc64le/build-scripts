#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : dom4j
# Version       : version-2.1.4
# Source repo   : https://github.com/dom4j/dom4j.git
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

PACKAGE_NAME=dom4j
PACKAGE_VERSION=${1:-version-2.1.4}
PACKAGE_URL=https://github.com/dom4j/dom4j.git
BUILD_HOME=$(pwd)
GRADLE_VERSION=6.2.2
JAR_PATH="build/libs/dom4j.jar"

# -------------------------
# Environment Setup
# -------------------------
yum install -y git wget unzip java-11-openjdk java-11-openjdk-devel

# Setting up Java environment...
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
export PATH="$JAVA_HOME/bin:$PATH"

#Installing Gradle
wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
unzip -q gradle-${GRADLE_VERSION}-bin.zip -d /usr/local/
export GRADLE_HOME="/usr/local/gradle-${GRADLE_VERSION}"
export PATH="$GRADLE_HOME/bin:$PATH"
rm -f gradle-${GRADLE_VERSION}-bin.zip

# -------------------------
# Clone Repository
# -------------------------
cd "$BUILD_HOME"
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

# -------------------------
# Build
# -------------------------
ret=0
gradle clean build -x test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "[ERROR] $PACKAGE_NAME - Build failed."
    exit 1
else
    echo "[SUCCESS] $PACKAGE_NAME - Build completed successfully."
fi

# -------------------------
# Test
# -------------------------
gradle test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "[ERROR] $PACKAGE_NAME - Tests failed."
    exit 2
else
    echo "[SUCCESS] $PACKAGE_NAME - All tests passed successfully."
fi

# -------------------------
# Smoke Test
# -------------------------
echo "[INFO] Verifying JAR output..."
ret=0
if [ ! -f "$JAR_PATH" ]; then
    echo "[ERROR] $PACKAGE_NAME - JAR not found at $JAR_PATH"
    exit 2
else
    echo "[SUCCESS] ${PACKAGE_NAME} - JAR built successfully: $(basename "$JAR_PATH")"
	echo "[PASS] ${PACKAGE_NAME}_${PACKAGE_VERSION} Build and Test successful."
    exit 0
fi
