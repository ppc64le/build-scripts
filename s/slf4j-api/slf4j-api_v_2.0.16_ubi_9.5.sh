#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : slf4j-api
# Version       : 2.0.16
# Source repo   : https://github.com/qos-ch/slf4j.git
# Tested on     : UBI 9.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the
#             mentioned platform using the specified version.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# ----------------------------- Variables -------------------------------------
PACKAGE_NAME="slf4j"
MODULE_NAME="slf4j-api"
PACKAGE_VERSION="${1:-2.0.16}"
PACKAGE_URL="https://github.com/qos-ch/${PACKAGE_NAME}.git"
GIT_TAG="v_${PACKAGE_VERSION}"
BUILD_HOME="$(pwd)"

# ---------------------- Install Dependencies ---------------------------------
yum install -y git wget java-17-openjdk-devel

# ---------------------- Setup Java Environment -------------------------------
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
export PATH="$JAVA_HOME/bin:$PATH"

# ---------------------- Install Maven ----------------------------------------
MAVEN_VERSION="${MAVEN_VERSION:-3.9.6}"
cd /opt
wget -q https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
ln -s apache-maven-${MAVEN_VERSION} maven
rm -f apache-maven-${MAVEN_VERSION}-bin.tar.gz

export MVN_HOME="/opt/maven"
export PATH="$MVN_HOME/bin:$PATH"

# ---------------------- Clone Repository -------------------------------------
cd "$BUILD_HOME"
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "tags/${GIT_TAG}" -b "${PACKAGE_VERSION}"

# ---------------------- Build Phase ------------------------------------------
cd "${MODULE_NAME}"
ret=0
mvn -B -ntp clean package -Dgpg.skip || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "[ERROR] Build failed for ${MODULE_NAME}-${PACKAGE_VERSION}"
    exit 1
fi

# ---------------------- Test Phase -------------------------------------------
mvn -B -ntp test -Dgpg.skip || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "[ERROR] Tests failed for ${MODULE_NAME}-${PACKAGE_VERSION}"
    exit 2
fi

# ---------------------- Smoke Test -------------------------------------------
TARGET_PATH="target"
JAR_FILE="${TARGET_PATH}/${MODULE_NAME}-${PACKAGE_VERSION}.jar"

if [ -f "$JAR_FILE" ]; then
    echo "[INFO] Main JAR file created: $JAR_FILE"
    echo "[SUCCESS] ${MODULE_NAME}-${PACKAGE_VERSION} build and test completed successfully."
	exit 0
else
    echo "[WARNING] Expected JAR file not found: $JAR_FILE"
    exit 2
fi
