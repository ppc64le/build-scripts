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

PACKAGE_NAME=sql
PACKAGE_URL=https://github.com/opensearch-project/sql
PACKAGE_VERSION=${1:-2.19.2.0}
OPENSEARCH_URL=https://github.com/opensearch-project/OpenSearch.git
OPENSEARCH_VERSION=2.19.2
OPENSEARCH_PACKAGE=OpenSearch
wdir=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

sudo yum install -y  git java-21-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin

cd $wdir
git clone ${OPENSEARCH_URL}
cd ${OPENSEARCH_PACKAGE} && git checkout ${OPENSEARCH_VERSION}
git apply $SCRIPT_DIR/${OPENSEARCH_PACKAGE}_${OPENSEARCH_VERSION}.patch
./gradlew -p distribution/archives/linux-ppc64le-tar assemble

# Export Custom Distribution path
export OPENSEARCH_DIST_PATH=file://${wdir}/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-${OPENSEARCH_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz

cd $wdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME && git checkout $PACKAGE_VERSION
git apply  $SCRIPT_DIR/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch

# --------
# Build
# --------
ret=0
./gradlew build -x test -x integTest -x async-query:jacocoTestCoverageVerification || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
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
./gradlew integTest -PcustomDistributionUrl=file://${wdir}/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-${OPENSEARCH_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

echo "Skipping async-query:jacocoTestCoverageVerification in build as it is in parity with intel and is flaky"
echo "Disabling testExtractDatePartWithTimeType in unit test as it is in parity with intel and is flaky"