#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : opensearch-jvector
# Version          : 3.6.0.0
# Source repo      : https://github.com/opensearch-project/opensearch-jvector.git
# Tested on        : UBI 9.6
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ethan Choe <ethanchoe@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME=opensearch-jvector
PACKAGE_URL=https://github.com/opensearch-project/opensearch-jvector.git
SCRIPT_PACKAGE_VERSION=3.6.0.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
OPENSEARCH_URL=https://github.com/opensearch-project/OpenSearch.git
OPENSEARCH_VERSION=${PACKAGE_VERSION::-2}
OPENSEARCH_PACKAGE=OpenSearch
BUILD_HOME=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname $SCRIPT)

sudo yum install -y git wget

# ----------------------------------------------
# Install java25
# ----------------------------------------------
sudo dnf install -y java-25-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-25-openjdk
export PATH="/usr/local/bin:$HOME/.local/bin:$JAVA_HOME/bin:$PATH"

sudo chown -R test_user:test_user /home/tester

# -------------------------------
# Remove existing repositories (if they exist)
# -------------------------------
cd "${BUILD_HOME}"

if [ -d "${OPENSEARCH_PACKAGE}" ]; then
    echo "Removing existing ${OPENSEARCH_PACKAGE} directory..."
    rm -rf "${OPENSEARCH_PACKAGE}"
fi

if [ -d "${PACKAGE_NAME}" ]; then
    echo "Removing existing ${PACKAGE_NAME} directory..."
    rm -rf "${PACKAGE_NAME}"
fi

# ----------------------------------------------
# Build opensearch tarball for integation tests
# ----------------------------------------------
cd $BUILD_HOME
git clone ${OPENSEARCH_URL}
cd ${OPENSEARCH_PACKAGE} && git checkout ${OPENSEARCH_VERSION}
./gradlew -p distribution/archives/linux-ppc64le-tar assemble
if [ $? != 0 ]
then
  echo "Build failed for OpenSearch-$OPENSEARCH_VERSION"
  exit 1
fi

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}" && git checkout "${PACKAGE_VERSION}"
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch

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
export OPENSEARCH_JVECTOR_ZIP=${BUILD_HOME}/${PACKAGE_NAME}/build/distributions/${PACKAGE_NAME}-${PACKAGE_VERSION}-SNAPSHOT.zip

# ----------
# Unit Test
# ----------
ret=0
./gradlew test -x integTest || ret=$?
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
./gradlew integTest -Dtests.jvm.argline="-Xms2g -Xmx2g" -PcustomDistributionUrl="${BUILD_HOME}/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-${OPENSEARCH_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz" || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

# If we reach here, both the build and tests were successful
set +ex
echo "------------------ ${PACKAGE_NAME} ${PACKAGE_VERSION} Build and Tests Successful ------------------"
echo "------------------ Plugin zip available at $OPENSEARCH_JVECTOR_ZIP --------------------------------"
exit 0
