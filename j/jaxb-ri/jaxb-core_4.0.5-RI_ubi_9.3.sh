#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : jaxb-core
# Version       : 4.0.5-RI
# Source repo   : https://github.com/eclipse-ee4j/jaxb-ri.git
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
PACKAGE_NAME="jaxb-ri"
MODULE_NAME="jaxb-ri/core"
PACKAGE_VERSION="${1:-4.0.5}"
PACKAGE_URL="https://github.com/eclipse-ee4j/${PACKAGE_NAME}.git"
GIT_TAG="${PACKAGE_VERSION}-RI"
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
mvn -B clean package -DskipTests -Dgpg.skip || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "[ERROR] Build failed for ${MODULE_NAME}-${PACKAGE_VERSION}"
    exit 1
fi

# ---------------------- Test Phase -------------------------------------------
mvn -B test -Dgpg.skip || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "[ERROR] Tests failed for ${MODULE_NAME}-${PACKAGE_VERSION}"
    exit 2
fi

# ---------------------- Smoke Test -------------------------------------------
TARGET_PATH="target"
JAR_FILE="${TARGET_PATH}/jaxb-core-${PACKAGE_VERSION}.jar"

if [ -f "$JAR_FILE" ]; then
    echo "[INFO] Main JAR file created: $JAR_FILE"
    echo "[SUCCESS] jaxb-core-${PACKAGE_VERSION} build and test completed successfully."
    exit 0
else
    echo "[WARNING] Expected JAR file not found: $JAR_FILE"
    exit 2
fi
