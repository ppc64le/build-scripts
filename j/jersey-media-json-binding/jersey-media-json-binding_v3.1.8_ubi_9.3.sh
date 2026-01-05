#!/bin/bash -e
###############################################################################
#
# Package         : jersey-media-json-binding
# Version         : 3.1.8
# Source repo     : https://github.com/eclipse-ee4j/jersey.git
# Language        : Java
# Tested on       : UBI 9.3 (ppc64le)
# Ci-Check    : True
# Maintainer      : Amit Kumar <amit.kumar282@ibm.com>
# License         : Apache License, Version 2.0 or later
#
# Disclaimer      : This script has been tested in root mode on the specified
#                   platform using the stated version. It may not work as 
#                   expected with newer versions or different environments.
#
###############################################################################

# -------------------------------
# Configuration & Initialization
# -------------------------------
PACKAGE_NAME="jersey"
MODULE_NAME="jersey-media-json-binding"
PACKAGE_VERSION="${1:-3.1.8}"
PACKAGE_URL="https://github.com/eclipse-ee4j/jersey.git"
BUILD_HOME="$(pwd)"

# -------------------------------
# Install Dependencies
# -------------------------------
yum install -y git java-17-openjdk java-17-openjdk-devel wget

# Install Maven
MAVEN_VERSION=3.9.6
cd /opt
wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -xvzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
ln -s apache-maven-${MAVEN_VERSION} maven
export MAVEN_HOME=/opt/maven
export PATH=${MAVEN_HOME}/bin:$PATH

# -------------------------------
# Clone Repository
# -------------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"
cd "media/json-binding"

# -------------------------------
# Build the Package
# -------------------------------
ret=0
mvn clean install -DskipTests || ret=$?
if [ $ret -ne 0 ]; then
   echo "------------------ ${MODULE_NAME}: Build Failed ------------------"
   exit 1
else
    echo "------------------ ${MODULE_NAME}: Build Passed ------------------"
fi

# -------------------------------
# Run Tests
# -------------------------------
mvn test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${MODULE_NAME}: Tests Failed ------------------"
    exit 1
else
    echo "------------------ ${MODULE_NAME}: Tests Passed ------------------"
fi

# -------------------------------
# Smoke Test - Validate Version
# -------------------------------

ACTUAL_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
if [[ "$ACTUAL_VERSION" == "$PACKAGE_VERSION" ]]; then
    echo "PASS: ${MODULE_NAME} version $PACKAGE_VERSION built successfully."
    exit 0
else
    echo "FAIL: Version ${MODULE_NAME} (expected $PACKAGE_VERSION, got $ACTUAL_VERSION)."
    exit 2
fi

