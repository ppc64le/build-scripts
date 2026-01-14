#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : user-behavior-insights
# Version          : 3.3.0.0
# Source repo      : https://github.com/opensearch-project/user-behavior-insights
# Tested on        : UBI:9.6
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Manya Rusiya <Manya.Rusiya@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME=user-behavior-insights
PACKAGE_URL=https://github.com/opensearch-project/user-behavior-insights
SCRIPT_PACKAGE_VERSION="3.3.0.0"
PACKAGE_VERSION="${1:-$SCRIPT_PACKAGE_VERSION}"
OPENSEARCH_VERSION="${PACKAGE_VERSION::-2}"
OPENSEARCH_PACKAGE="OpenSearch"
wdir=`pwd`

yum install -y git java-21-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin


#--------------------------------
#Build opensearch-project and publish build tools 
#-------------------------------
cd $wdir
git clone https://github.com/opensearch-project/OpenSearch.git
cd OpenSearch
git checkout $OPENSEARCH_VERSION
./gradlew -p distribution/archives/linux-ppc64le-tar assemble
./gradlew -Prelease=true publishToMavenLocal
./gradlew :build-tools:publishToMavenLocal


# ---------------------------
# Build Job Scheduler
# ---------------------------
cd $wdir
git clone https://github.com/opensearch-project/job-scheduler
cd job-scheduler
git checkout $PACKAGE_VERSION
./gradlew assemble
./gradlew -Prelease=true publishToMavenLocal



cd $wdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME && git checkout $PACKAGE_VERSION


if ! ./gradlew build ; then
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
