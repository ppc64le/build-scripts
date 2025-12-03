#!/bin/bash -e
###############################################################################
#
# Package         : icu
# Version         : release-76-1
# Source repo     : https://github.com/unicode-org/icu.git
# Language        : C++,Java
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
PACKAGE_NAME="icu"
PACKAGE_VERSION="${1:-release-76-1}"
PACKAGE_URL="https://github.com/unicode-org/icu.git"
JAVA_MODULE="icu4j"
C_MODULE="icu4c"
BUILD_HOME="$(pwd)"

# -------------------------------
# Install Dependencies
# -------------------------------
yum install -y git wget gcc gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Install Maven
MAVEN_VERSION=3.9.6
wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -zxf apache-maven-${MAVEN_VERSION}-bin.tar.gz
cp -R apache-maven-${MAVEN_VERSION} /usr/local
ln -sf /usr/local/apache-maven-${MAVEN_VERSION}/bin/mvn /usr/bin/mvn

# -------------------------------
# Clone Repository
# -------------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# -------------------------------
# Build and Test: Java (icu4j)
# -------------------------------
cd "${JAVA_MODULE}"

ret=0
mvn clean install || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${PACKAGE_NAME}:${JAVA_MODULE}:: Build Failed ------------------"
    exit 1
fi

mvn test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${PACKAGE_NAME}:${JAVA_MODULE}:: Tests Failed ------------------"
    exit 2
else
    echo "------------------ ${PACKAGE_NAME}:${JAVA_MODULE}:: Tests Passed ------------------"
fi

# -------------------------------
# Build and Test: C/C++ (icu4c)
# -------------------------------
cd "../${C_MODULE}/source"
mkdir -p /tmp/icu_cnfg
./runConfigureICU Linux --prefix=/tmp/icu_cnfg

make -j$(nproc) install || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${PACKAGE_NAME}:${C_MODULE}:: Build Failed ------------------"
    exit 1
fi

make check || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${PACKAGE_NAME}:${C_MODULE}:: Tests Failed ------------------"
    exit 2
else
    echo "------------ ${PACKAGE_NAME}:${C_MODULE}:: Tests Passed ------------------------"
    echo "------------ ${PACKAGE_NAME}_${PACKAGE_VERSION}:: Build and Test Success -------"
    exit 0
fi

