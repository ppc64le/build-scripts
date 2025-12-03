#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : opensearch-prometheus-exporter
# Version          : 3.2.0.0
# Source repo      : https://github.com/opensearch-project/opensearch-prometheus-exporter.git
# Tested on        : UBI 9.6
# Language         : Java
# Ci-Check     : True
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

PACKAGE_NAME=opensearch-prometheus-exporter
PACKAGE_URL=https://github.com/opensearch-project/opensearch-prometheus-exporter.git
PACKAGE_VERSION=${1:-3.2.0.0}
BUILD_HOME=`pwd`

sudo yum install -y  git wget

# ----------------------------------------------
# Install temurin java21
# ----------------------------------------------
sudo wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.2%2B13/OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.2_13.tar.gz
sudo tar -C /usr/local -zxf OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.2_13.tar.gz
export JAVA_HOME=/usr/local/jdk-21.0.2+13/
export JAVA21_HOME=/usr/local/jdk-21.0.2+13/
export PATH=$PATH:/usr/local/jdk-21.0.2+13/bin/
sudo ln -sf /usr/local/jdk-21.0.2+13/bin/java /usr/bin/
sudo rm -rf OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.2_13.tar.gz

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