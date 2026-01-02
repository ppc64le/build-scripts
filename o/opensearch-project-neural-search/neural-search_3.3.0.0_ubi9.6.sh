#!/bin/bash -ex
# --------------------------------------------------------------------------------
# Package        : neural-search
# Version        : 3.3.0.0
# Source repo    : https://github.com/opensearch-project/neural-search
# Tested on      : UBI 9.6
# Language       : Java
# Ci-Check       : false
# Maintainer     : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
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
SCRIPT_PACKAGE_VERSION="3.3.0.0"
PACKAGE_VERSION="${1:-$SCRIPT_PACKAGE_VERSION}"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
OPENSEARCH_VERSION="${PACKAGE_VERSION::-2}"
OPENSEARCH_PACKAGE="OpenSearch"
OPENSEARCH_URL=https://github.com/${PACKAGE_ORG}/${OPENSEARCH_PACKAGE}.git
SCRIPT_PATH=$(dirname $(realpath $0))
RUNTESTS=1
DJL_HOME="$HOME/.djl.ai"
PYTORCH_VERSION="1.13.1"
DJL_VERSION="v0.33.0"
PYTHON_VERSION="3.9"
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
sudo yum install -y git wget sudo unzip make cmake gcc gcc-c++ perl python3-devel python3-pip java-21-openjdk-devel
export JAVA_HOME=$(ls -d /usr/lib/jvm/java-21-openjdk-* | head -n1)
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

# -------------------------------------------------------
# Build and install djl/ml-commons for integration tests
# -------------------------------------------------------
cd $BUILD_HOME
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-ml-commons/ml-commons_3.3.0.0_ubi9.6.sh
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-ml-commons/ml-commons_3.3.0.0.patch
chmod +x ml-commons_3.3.0.0_ubi9.6.sh
./ml-commons_3.3.0.0_ubi9.6.sh $PACKAGE_VERSION --skip-tests
rm -rf ml-commons_3.3.0.0_ubi9.6.sh ml-commons_3.3.0.0.patch 

# ----------------------------------------------
# Build opensearch tarball for integation tests
# ----------------------------------------------
cd "$BUILD_HOME"

if [ ! -d "$BUILD_HOME/OpenSearch" ]; then
  git clone https://github.com/opensearch-project/OpenSearch
  cd OpenSearch
  git checkout "$OPENSEARCH_VERSION"
  ./gradlew --no-daemon -p distribution/archives/linux-ppc64le-tar assemble
else
  echo "OpenSearch directory already exists. Skipping clone and build."
fi


# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd $BUILD_HOME
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout $PACKAGE_VERSION
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}-$SCRIPT_PACKAGE_VERSION.patch


# --------
# Build
# --------
ret=0
./gradlew  build -x test -x integTest -Dbuild.snapshot=false -Dorg.opensearch.djl.pytorch.path=$DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
fi

# --------
# Install
# --------
./gradlew  -Prelease=true publishToMavenLocal -Dorg.opensearch.djl.pytorch.path=$DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le


# ---------------------------
# Skip Tests?
# ---------------------------
if [ "$RUNTESTS" -eq 0 ]; then
        set +ex
        echo "------------------ Complete: Build and install successful! Tests skipped. ------------------"
        exit 0
fi

mkdir -p  build/dependencies/opensearch-ml-plugin
cp $HOME/.m2/repository/org/opensearch/plugin/opensearch-ml-plugin/$PACKAGE_VERSION-SNAPSHOT/opensearch-ml-plugin-$PACKAGE_VERSION-SNAPSHOT.zip build/dependencies/opensearch-ml-plugin/


mkdir -p build/dependencies/opensearch-job-scheduler
cp $HOME/.m2/repository/org/opensearch/plugin/opensearch-job-scheduler/$PACKAGE_VERSION-SNAPSHOT/opensearch-job-scheduler-$PACKAGE_VERSION-SNAPSHOT.zip build/dependencies/opensearch-job-scheduler/


# ----------
# Unit Test
# ----------
ret=0
./gradlew  test -x integTest --continue -Dbuild.snapshot=false -Dorg.opensearch.djl.pytorch.path=$DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le || ret=$?
if [ $ret -ne 0 ]; then
		set +ex
		echo "------------------ ${PACKAGE_NAME}: Unit Test Failed ------------------"
		exit 2
fi

# -----------------
# Integration Test
# -----------------
ret=0
./gradlew integTest -PcustomDistributionUrl=$BUILD_HOME/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-$OPENSEARCH_VERSION-SNAPSHOT-linux-ppc64le.tar.gz   -Dbuild.snapshot=false -Dorg.opensearch.djl.pytorch.path=$DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

set +ex
echo "------------------ Complete: Build and Tests successful! ------------------"
echo "CI checks are disabled for this script due to the build time exceeding the maximum execution limit (6 hours) on GitHub Actions."

