#!/bin/bash -ex
# ----------------------------------------------------------------------------------------
# Package        : opensearch-learning-to-rank-base
# Version        : 2.19.2.0
# Source repo    : https://github.com/opensearch-project/opensearch-learning-to-rank-base
# Tested on      : UBI 9.5
# Language       : Java
# Ci-Check   : true
# Maintainer     : Sumit Dubey <sumit.dubey2@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in non root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# -----------------------------------------------------------------------------------------

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
PACKAGE_NAME="opensearch-learning-to-rank-base"
PACKAGE_ORG="opensearch-project"
PACKAGE_VERSION="2.19.2.0"
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
sudo tee /etc/yum.repos.d/adoptium.repo >/dev/null <<EOF
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/${DISTRIBUTION_NAME:-$(. /etc/os-release; echo $ID)}/\$releasever/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF
sudo yum install -y git wget temurin-17-jdk
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/temurin-17-jdk*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

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

