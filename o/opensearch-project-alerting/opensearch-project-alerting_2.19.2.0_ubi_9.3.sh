#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : alerting
# Version          : 2.19.2.0
# Source repo      : https://github.com/opensearch-project/alerting
# Tested on        : UBI 9.3
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

PACKAGE_NAME=alerting
PACKAGE_URL=https://github.com/opensearch-project/alerting
PACKAGE_VERSION=${1:-2.19.2.0}
OPENSEARCH_URL=https://github.com/opensearch-project/OpenSearch.git
OPENSEARCH_VERSION=${PACKAGE_VERSION::-2}
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

cd $wdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME && git checkout $PACKAGE_VERSION

#skipping the licenseHeader task as failure is in parity with x86
#skipping the tests related to backward compatibity (bwc) which needs old opensearch tarball (opensearch-min-1.1.0-linux-ppc64le.tar.gz)
if ! ./gradlew build -x alerting-sample-remote-monitor-plugin:licenseHeaders -x alerting:alertingBwcCluster#oldVersionClusterTask1 -x alerting:alertingBwcCluster#fullRestartClusterTask -x alerting:alertingBwcCluster#oldVersionClusterTask0 -x alerting:alertingBwcCluster#mixedClusterTask -x alerting:alertingBwcCluster#twoThirdsUpgradedClusterTask -x alerting:alertingBwcCluster#rollingUpgradeClusterTask -PcustomDistributionUrl="$wdir/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-${OPENSEARCH_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz"; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
elif ! ./gradlew test; then
    echo "------------------$PACKAGE_NAME::Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Test_fails"
    exit 2
else
    # If both the build and test are successful, print the success message
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi