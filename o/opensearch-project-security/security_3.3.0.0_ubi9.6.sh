#!/bin/bash -ex
# --------------------------------------------------------------------------------
# Package        : security (opensearch)
# Version        : 3.3.0.0
# Source repo    : https://github.com/opensearch-project/security
# Tested on      : UBI 9.6
# Language       : Java
# Ci-Check       : True
# Maintainer     : Pratik Tonage <Pratik.Tonage@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# -------------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="security"
PACKAGE_ORG="opensearch-project"
PACKAGE_VERSION="3.3.0.0"
COMMON_UTILS_VERSION="3.2.0.0"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
OPENSEARCH_VERSION="${PACKAGE_VERSION::-2}"
SCRIPT_PATH=$(dirname $(realpath $0))
RUNTESTS=1
BUILD_HOME="$(pwd)"

# -------------------
# Parse CLI Arguments
# -------------------
for i in "$@"; do
  case $i in
    --skip-tests)
      RUNTESTS=0
      echo "Skipping tests"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 3
      ;;
    *)
      PACKAGE_VERSION=$i
      echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"
      ;;
  esac
done

# ---------------------------
# Dependency Installation
# ---------------------------
yum install -y git wget
wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.9%2B10/OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.9_10.tar.gz
tar -C /usr/local -zxf OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.9_10.tar.gz
export JAVA_HOME=/usr/local/jdk-21.0.9+10/
export JAVA21_HOME=/usr/local/jdk-21.0.9+10/
export PATH=$PATH:/usr/local/jdk-21.0.9+10/bin/
ln -sf /usr/local/jdk-21.0.9+10/bin/java /usr/bin/
rm -rf OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.9_10.tar.gz

#--------------------------------
#Build opensearch-project and publish build tools
#-------------------------------
cd ${BUILD_HOME}
git clone https://github.com/opensearch-project/OpenSearch.git
cd OpenSearch
git checkout $OPENSEARCH_VERSION
./gradlew -p distribution/archives/linux-ppc64le-tar assemble
./gradlew -Prelease=true publishToMavenLocal
./gradlew :build-tools:publishToMavenLocal


# ------------------------------
# Build Opensearch common-utils
# ------------------------------
cd ${BUILD_HOME}
git clone https://github.com/opensearch-project/common-utils.git
cd common-utils
git checkout "${COMMON_UTILS_VERSION}"
git apply ${SCRIPT_PATH}/common-utils_${PACKAGE_VERSION}.patch
./gradlew assemble
./gradlew -Prelease=true publishToMavenLocal

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"
git apply ${SCRIPT_PATH}/${PACKAGE_ORG}-${PACKAGE_NAME}_${PACKAGE_VERSION}.patch

# --------
# Build
# --------
ret=0
./gradlew clean assemble || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
fi
export OPENSEARCH_SECURITY_ZIP=${BUILD_HOME}/${PACKAGE_NAME}/build/distributions/opensearch-security-${PACKAGE_VERSION}-SNAPSHOT.zip

# test might not pass as its flaky
# ---------------------------
# Skip Tests?
# ---------------------------
if [ "$RUNTESTS" -eq 0 ]; then
        set +ex
        echo "------------------ Complete: Build successful! Tests skipped. ------------------"
        exit 0
fi

# ----------
# Unit Test
# ----------
ret=0
env -i PATH=/usr/bin:/bin JAVA_HOME=$JAVA_HOME ./gradlew test -x integrationTest || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Unit Test Failed ------------------"
	exit 2
fi

# -----------------
# Integration Test
# -----------------
ret=0
./gradlew integrationTest || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

set +ex
echo "Complete: Build and Tests successful!"
echo "Plugin zip available at [${OPENSEARCH_SECURITY_ZIP}]"
echo "Installation instructions available at https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}/blob/${PACKAGE_VERSION}/DEVELOPER_GUIDE.md#building"
