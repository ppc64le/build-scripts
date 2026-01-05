#!/bin/bash -e
###############################################################################
#
# Package         : openapi-generator
# Version         : 7.2.0
# Source repo     : https://github.com/OpenAPITools/openapi-generator.git
# Language        : Java
# Tested on       : UBI 9.3 (ppc64le)
# Ci-Check    : True
# Maintainer      : Simran Sirsat <Simran.Sirsat@ibm.com>
# License         : Apache License, Version 2.0 or later
#
# Disclaimer      : This script has been tested in root mode on the specified
#                   platform using the stated version. It may not work as 
#                   expected with newer versions or different environments.
#
###############################################################################


# Configuration & Initialization
PACKAGE_NAME="openapi-generator"
PACKAGE_VERSION="${1:-v7.2.0}"
PACKAGE_URL="https://github.com/OpenAPITools/openapi-generator.git"
BUILD_HOME="$(pwd)"

# Install Dependencies
yum install -y git java-17-openjdk java-17-openjdk-devel wget

# Install Maven
MAVEN_VERSION=3.9.6
cd /opt
wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -xvzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
ln -s apache-maven-${MAVEN_VERSION} maven
export MAVEN_HOME=/opt/maven
export PATH=${MAVEN_HOME}/bin:$PATH

# Clone Repository
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# Build the Specific Module
ret=0
./mvnw clean install || ret=$?
if [ $ret -ne 0 ]; then
   echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
   exit 1
else
    echo "------------------ ${PACKAGE_NAME}: Build Passed ------------------"
fi

# Run Tests
mvn test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${PACKAGE_NAME}: Tests Failed ------------------"
    exit 1
else
    echo "------------------ ${PACKAGE_NAME}: Tests Passed ------------------"
fi