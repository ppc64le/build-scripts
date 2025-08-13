#!/bin/bash -e
###############################################################################
#
# Package         : commons-lang
# Version         : rel/commons-lang-3.17.0
# Source repo     : https://github.com/apache/commons-lang.git
# Language        : Java
# Tested on       : UBI 9.5 (ppc64le)
# Travis-Check    : True
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
PACKAGE_NAME="commons-lang"
PACKAGE_VERSION="${1:-3.17.0}"
GIT_TAG="rel/commons-lang-${PACKAGE_VERSION}"
PACKAGE_URL="https://github.com/apache/commons-lang.git"
BUILD_HOME="$(pwd)"
SCRIPT_PATH=$(dirname $(realpath $0))

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
git checkout "${GIT_TAG}"

# ---------------------------------------------
# Adding ppc64le support to ArchUtils.java
# ---------------------------------------------
#Error on power: ArchUtilsTest.testGetProcessor:130 NullPointer

ARCHUTILS_FILE="src/main/java/org/apache/commons/lang3/ArchUtils.java"
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_v${PACKAGE_VERSION}.patch

# -------------------------------
# Build & Install
# -------------------------------
ret=0
mvn clean install -DskipTests || ret=$?
if [ $ret -ne 0 ]; then
   echo "------------------ ${PACKAGE_NAME}:: Build Failed ----------------------"
   exit 1
else
    echo "----------------- ${PACKAGE_NAME}:: Build Passed ----------------------"
fi

# -------------------------------
# Run Tests
# -------------------------------
mvn test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${PACKAGE_NAME}:: Tests Failed ---------------------"
    exit 2
else
    echo "------------------ ${PACKAGE_NAME}:: Tests Passed ---------------------"
	echo "[PASS]: ${PACKAGE_NAME} version ${GIT_TAG} build and test successfully."
	exit 0
fi
