#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : observability
# Version          : 3.3.0.0
# Source repo      : https://github.com/opensearch-project/observability
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

# Install sudo for non-root user execution
# yum install sudo -y
# ---------------------------
# Check for root user
# ---------------------------
if ! ((${EUID:-0} || "$(id -u)")); then
	set +ex
        echo "FAIL: This script must be run as a non-root user with sudo permissions"
        exit 3
fi

PACKAGE_NAME=observability
PACKAGE_URL=https://github.com/opensearch-project/observability
PACKAGE_VERSION=${1:-3.3.0.0}
BUILD_HOME="$(pwd)"
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

sudo yum install -y git java-21-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# ------------------------------
# Build Opensearch common-utils
# ------------------------------
cd $BUILD_HOME
git clone https://github.com/opensearch-project/common-utils.git
cd common-utils
git checkout $PACKAGE_VERSION
./gradlew assemble
./gradlew -Prelease=true publishToMavenLocal

cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply $SCRIPT_DIR/observability_3.3.0.0.patch

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
