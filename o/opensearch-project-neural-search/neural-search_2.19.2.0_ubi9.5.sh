#!/bin/bash -ex
# --------------------------------------------------------------------------------
# Package        : neural-search
# Version        : 2.19.2.0
# Source repo    : https://github.com/opensearch-project/neural-search
# Tested on      : UBI 9.5
# Language       : Java
# Ci-Check   : false
# Maintainer     : Sumit Dubey <sumit.dubey2@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in non root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# -------------------------------------------------------------------------------

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
PACKAGE_NAME="neural-search"
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

# -------------------------------------------------------
# Build and install djl/ml-commons for integration tests
# -------------------------------------------------------
cd $BUILD_HOME
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/m/ml-commons/ml-commons_2.19.2.0_ubi9.5.sh
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/m/ml-commons/ml-commons_2.19.2.0.patch
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/m/ml-commons/djl_v0.33.0.patch
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/m/ml-commons/onnxruntime_v1.17.1.patch
chmod +x ml-commons_2.19.2.0_ubi9.5.sh
./ml-commons_2.19.2.0_ubi9.5.sh --skip-tests
rm -rf ml-commons_2.19.2.0_ubi9.5.sh ml-commons_2.19.2.0.patch djl_v0.33.0.patch onnxruntime_v1.17.1.patch

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

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch

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

# --------
# Install
# --------
./gradlew -Prelease=true publishToMavenLocal

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
./gradlew test -x integTest --continue || ret=$?
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
./gradlew :integTest -PnumNodes=3 -PcustomDistributionDownloadType=bundle -PcustomDistributionUrl=${BUILD_HOME}/opensearch-build/tar/builds/opensearch/dist/opensearch-min-${OPENSEARCH_BUILD_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz -Dtests.heap.size=4096m || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

set +ex
echo "------------------ Complete: Build and Tests successful! ------------------"
echo "The following two unit tests were disabled because they are in parity with Intel:"
echo "    org.opensearch.neuralsearch.query.HybridQueryBuilderTests.testDoToQuery_whenOneSubquery_thenBuildSuccessfully"
echo "    org.opensearch.neuralsearch.query.HybridQueryBuilderTests.testDoToQuery_whenMultipleSubqueries_thenBuildSuccessfully"

