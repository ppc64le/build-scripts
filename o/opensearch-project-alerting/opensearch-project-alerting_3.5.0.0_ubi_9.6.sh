#!/bin/bash -ex
# --------------------------------------------------------------------------------
# Package        : alerting (opensearch)
# Version        : 3.5
# Source repo    : https://github.com/opensearch-project/alerting
# Tested on      : UBI 9.6
# Language       : Java
# Maintainer     : Shubhada Salunkhe <Shubhada.salunkhe@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# --------------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="alerting"
PACKAGE_ORG="opensearch-project"
PACKAGE_VERSION="3.5"
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
yum install -y git wget gcc gcc-c++ make cmake \
  python3 python3-devel \
  openssl-devel bzip2-devel zlib-devel \
  java-21-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

git apply ${SCRIPT_PATH}/alerting.patch

# --------
# Build
# --------
ret=0
./gradlew clean assemble || ret=$?
if [ $ret -ne 0 ]; then
    set +ex
    echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi

export OPENSEARCH_ALERTING_ZIP=${BUILD_HOME}/${PACKAGE_NAME}/alerting/build/distributions/opensearch-alerting-3.5.0.0-SNAPSHOT.zip

# ---------------------------
# Skip Tests?
# ---------------------------
if [ "$RUNTESTS" -eq 0 ]; then
    set +ex
    echo "------------------ Complete: Build successful! Tests skipped ------------------"
    exit 0
fi

# ----------
# Unit Test
# ----------
ret=0
env -i PATH=/usr/bin:/bin JAVA_HOME=$JAVA_HOME ./gradlew test \
    -x :alerting:compileKotlin \
    -x :alerting:compileTestKotlin || ret=$?

if [ $ret -ne 0 ]; then
    set +ex
    echo "------------------ ${PACKAGE_NAME}: Unit Test Failed ------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Unit_Test_Fails"
    exit 2
fi


# ---------------------------
# Success
# ---------------------------
set +ex
echo "Complete: Build and Tests successful!"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
echo "Plugin zip available at [${OPENSEARCH_ALERTING_ZIP}]"

