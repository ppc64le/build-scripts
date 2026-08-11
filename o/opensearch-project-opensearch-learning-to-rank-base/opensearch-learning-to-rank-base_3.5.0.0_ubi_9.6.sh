#!/bin/bash -ex
# ----------------------------------------------------------------------------------------
# Package        : opensearch-learning-to-rank-base
# Version        : 3.5.0.0
# Source repo    : https://github.com/opensearch-project/opensearch-learning-to-rank-base
# Tested on      : UBI 9.6
# Language       : Java
# Ci-Check   : true
# Maintainer     : Shubhada Salunkhe <Shubhada.Salunkhe@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in non root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# -----------------------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="opensearch-learning-to-rank-base"
PACKAGE_ORG="opensearch-project"
PACKAGE_VERSION="3.5.0.0"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
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

sudo yum install -y git wget gcc gcc-c++ make cmake \
 python3 python3-devel \
 openssl-devel bzip2-devel zlib-devel \
 java-25-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-25-openjdk
export PATH=$JAVA_HOME/bin:$PATH

sudo chown -R test_user:test_user /home/tester

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"
git apply "${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch"


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
export OPENSEARCH_LEARNING_ZIP=${BUILD_HOME}/${PACKAGE_NAME}/build/distributions/opensearch-ltr-${PACKAGE_VERSION}-SNAPSHOT.zip

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
./gradlew test || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Unit Test Failed ------------------"
	exit 2
fi

# -----------------
# Integration Test
# -----------------
ret=0
./gradlew integTest || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

set +ex
echo "Complete: Build and Tests successful!"
echo "Plugin zip available at [${OPENSEARCH_LEARNING_ZIP}]"
echo "Installation instructions available at https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}/blob/${PACKAGE_VERSION}/README.md#installing"
