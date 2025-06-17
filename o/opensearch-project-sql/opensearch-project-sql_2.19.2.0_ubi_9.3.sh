#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : sql
# Version          : 2.19.2.0
# Source repo      : https://github.com/opensearch-project/sql
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
PACKAGE_NAME="sql"
PACKAGE_ORG="opensearch-project"
PACKAGE_VERSION="2.19.2.0"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
OPENSEARCH_BUILD_VERSION=2.19.2
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
sudo yum install -y git wget sudo unzip make cmake gcc gcc-c++ perl python3-devel python3-pip java-17-openjdk-devel
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-17-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

# ----------------------------------------------
# Build opensearch tarball for integation tests
# ----------------------------------------------
cd $BUILD_HOME
if [ -z "$(ls -A $BUILD_HOME/opensearch-build)" ]; then
	git clone https://github.com/opensearch-project/opensearch-build
	cd opensearch-build
	git checkout $OPENSEARCH_BUILD_VERSION
	rm -rf $HOME/.pyenv
	curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
	export PYENV_ROOT="$HOME/.pyenv"
	python3 -m pip install pipenv
	./build.sh manifests/$OPENSEARCH_BUILD_VERSION/opensearch-$OPENSEARCH_BUILD_VERSION.yml -s -c OpenSearch
fi

CUSTOM_OS_DIST=file://${BUILD_HOME}/opensearch-build/tar/builds/opensearch/dist/opensearch-min-${OPENSEARCH_BUILD_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz
# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"
git apply  $SCRIPT_DIR/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch

# --------
# Build
# --------
ret=0
./gradlew build -x test -x integTest -x async-query:jacocoTestCoverageVerification  -PcustomDistributionUrl=${BUILD_HOME}/opensearch-build/tar/builds/opensearch/dist/opensearch-min-${OPENSEARCH_BUILD_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
fi

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
./gradlew test  || ret=$?
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
./gradlew integTest  -PcustomDistributionUrl=${BUILD_HOME}/opensearch-build/tar/builds/opensearch/dist/opensearch-min-${OPENSEARCH_BUILD_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz -Dtests.heap.size=4096m || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

echo "Skipping async-query:jacocoTestCoverageVerification in build as it is flaky and in parity with intel"
echo "Disabling testExtractDatePartWithTimeType in unit test as it is in parity with intel and is flaky"