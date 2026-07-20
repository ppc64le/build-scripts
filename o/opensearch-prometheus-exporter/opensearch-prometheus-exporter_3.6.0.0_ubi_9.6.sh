#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : opensearch-prometheus-exporter
# Version          : 3.6.0.0
# Source repo      : https://github.com/opensearch-project/opensearch-prometheus-exporter.git
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

PACKAGE_NAME=opensearch-prometheus-exporter
PACKAGE_URL=https://github.com/opensearch-project/opensearch-prometheus-exporter.git
PACKAGE_VERSION=${1:-3.6.0.0}
BUILD_HOME=`pwd`

# ----------------------------------------------
# Install system packages
# ----------------------------------------------
sudo dnf install -y git wget

# ----------------------------------------------
# Install java25
# ----------------------------------------------
sudo dnf install -y java-25-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-25-openjdk
export PATH="/usr/local/bin:$HOME/.local/bin:$JAVA_HOME/bin:$PATH"

sudo chown -R test_user:test_user /home/tester

# -------------------------------
# Remove exiting repository (if exists)
# -------------------------------
if [ -d "${PACKAGE_NAME}" ]; then
    echo "Removing existing ${PACKAGE_NAME} directory..."
    rm -rf "${PACKAGE_NAME}"
fi

# -------------------------------
# Clone and Prepare Repository
# -------------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}" && git checkout "${PACKAGE_VERSION}"

# --------
# Build
# --------
ret=0
./gradlew clean build || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
        exit 1
fi

export OPENSEARCH_PROMETHEUS_EXPORTER_ZIP=${BUILD_HOME}/${PACKAGE_NAME}/build/distributions/prometheus-exporter-${PACKAGE_VERSION}.zip

# ----------------------------------
# Run complete test suite
# ----------------------------------
ret=0
./gradlew clean check || ret=$?
if [ $ret -ne 0 ]; then
        ret=0
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Test Suite Failed ------------------"
        exit 2
fi

# ---------------------------------------
# Backward Compatibility (BWC) Testing
# ---------------------------------------
ret=0
./bwctest.sh || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: BWC Tests Failed ------------------"
        exit 2
fi

# If we reach here, both the build and tests were successful
set +ex
echo "------------------ ${PACKAGE_NAME} ${PACKAGE_VERSION} Build and Tests Successful ------------------"
echo "------------------ Plugin zip available at $OPENSEARCH_PROMETHEUS_EXPORTER_ZIP --------------------------------"
exit 0
