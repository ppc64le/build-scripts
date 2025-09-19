#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : performance-analyzer
# Version          : 2.19.2.0
# Source repo      : https://github.com/opensearch-project/performance-analyzer
# Tested on        : UBI:9.3
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# ---------------------------
# Check for root user
# ---------------------------
if ! ((${EUID:-0} || "$(id -u)")); then
	set +ex
        echo "FAIL: This script must be run as a non-root user with sudo permissions"
        exit 3
fi

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME=performance-analyzer
PACKAGE_URL=https://github.com/opensearch-project/${PACKAGE_NAME}.git
PACKAGE_VERSION="2.19.2.0"
BUILD_HOME="$(pwd)"
RUNTESTS=1
COMMONS_PACKAGE=performance-analyzer-commons
COMMONS_URL=https://github.com/opensearch-project/performance-analyzer-commons.git
COMMONS_VERSION=1.6.0

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

# Install dependencies
sudo yum install -y git java-17-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# ---------------------------
# Build and publish performance-analyzer-commons to local Maven
# ---------------------------
cd $BUILD_HOME
git clone $COMMONS_URL
cd $COMMONS_PACKAGE && git checkout $COMMONS_VERSION
./gradlew publishToMavenLocal

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME && git checkout $PACKAGE_VERSION

# --------
# Build
# --------
ret=0
./gradlew build -x test -x integTest || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
fi
export OPENSEARCH_PER_ANALYZER_ZIP=${BUILD_HOME}/${PACKAGE_NAME}/build/distributions/opensearch-${PACKAGE_NAME}-${PACKAGE_VERSION}-SNAPSHOT.zip


# ---------------------------
# Skip Tests?
# ---------------------------
if [ "$RUNTESTS" -eq 0 ]; then
        set +ex
        echo "------------------ Complete: Build and install successful! Tests skipped. ------------------"
        exit 0
fi

# ----------
# Unit Test
# ----------
ret=0
./gradlew test || ret=$?
if [ $ret -ne 0 ]; then
        ret=0
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
echo "Plugin zip available at [${OPENSEARCH_PER_ANALYZER_ZIP}]"