#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : performance-analyzer
# Version          : 2.19.2.0
# Source repo      : https://github.com/opensearch-project/performance-analyzer
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

PACKAGE_NAME=performance-analyzer
PACKAGE_URL=https://github.com/opensearch-project/performance-analyzer
PACKAGE_VERSION=${1:-2.19.2.0}
wdir=`pwd`

COMMONS_PACKAGE=performance-analyzer-commons
COMMONS_URL=https://github.com/opensearch-project/performance-analyzer-commons.git
COMMONS_VERSION=1.6.0

# Install dependencies
sudo yum install -y git java-21-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Build and publish performance-analyzer-commons to local Maven
cd $wdir
git clone $COMMONS_URL
cd $COMMONS_PACKAGE && git checkout $COMMONS_VERSION
./gradlew publishToMavenLocal

# Build performance-analyzer
cd $wdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME && git checkout $PACKAGE_VERSION

if ! ./gradlew build; then
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
