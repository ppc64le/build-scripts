#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : security-analytics
# Version          : 2.19.2.0
# Source repo      : https://github.com/opensearch-project/security-analytics
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

PACKAGE_NAME=security-analytics
PACKAGE_URL=https://github.com/opensearch-project/${PACKAGE_NAME}
PACKAGE_VERSION=${1:-2.19.2.0}
OPENSEARCH_VERSION=${PACKAGE_VERSION::-2}
OPENSEARCH_PACKAGE=OpenSearch
OPENSEARCH_URL=https://github.com/opensearch-project/${OPENSEARCH_PACKAGE}.git
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

if ! ./gradlew build -PcustomDistributionUrl="$BUILD_HOME/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-${OPENSEARCH_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz"; then
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
    echo "------------------$PACKAGE_NAME:: Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi    