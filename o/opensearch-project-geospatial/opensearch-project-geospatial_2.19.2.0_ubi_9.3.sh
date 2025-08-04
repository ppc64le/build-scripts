#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : geospatial
# Version          : 2.19.2.0
# Source repo      : https://github.com/opensearch-project/geospatial
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

PACKAGE_NAME=geospatial
PACKAGE_URL=https://github.com/opensearch-project/geospatial
PACKAGE_VERSION=${1:-2.19.2.0}
OPENSEARCH_URL=https://github.com/opensearch-project/OpenSearch.git
OPENSEARCH_VERSION=${PACKAGE_VERSION::-2}
OPENSEARCH_PACKAGE=OpenSearch
BUILD_HOME=`pwd`

sudo yum install -y git java-21-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin

cd $BUILD_HOME
git clone ${OPENSEARCH_URL}
cd ${OPENSEARCH_PACKAGE} && git checkout ${OPENSEARCH_VERSION}
./gradlew -p distribution/archives/linux-ppc64le-tar assemble

cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME && git checkout $PACKAGE_VERSION

# --------
# Build
# --------
ret=0
./gradlew build -x test -x integTest  || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
fi
export OPENSEARCH_GEOSPATIAL_ZIP=${BUILD_HOME}/${PACKAGE_NAME}/build/distributions/opensearch-${PACKAGE_NAME}-${PACKAGE_VERSION}-SNAPSHOT.zip

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
./gradlew integTest -PcustomDistributionUrl="${BUILD_HOME}/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-${OPENSEARCH_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz" || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

set +ex
echo "------------------ Complete: Build and Tests successful! ------------------"
echo "Plugin zip available at [${OPENSEARCH_GEOSPATIAL_ZIP}]"
