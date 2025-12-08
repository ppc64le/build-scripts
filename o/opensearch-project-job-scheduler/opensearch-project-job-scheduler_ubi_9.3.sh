#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : job-scheduler
# Version          : 2.15.0.0
# Source repo      : https://github.com/opensearch-project/job-scheduler
# Tested on        : UBI:9.3
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME=job-scheduler
PACKAGE_URL=https://github.com/opensearch-project/job-scheduler
PACKAGE_VERSION=${1:-2.15.0.0}

sudo yum install -y  git gcc patch make java-17-openjdk-devel python3 python3-devel bzip2-devel zlib-devel openssl-devel
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./gradlew build -x :opensearch-job-scheduler-sample-extension:integTest ; then
    echo "------------------$PACKAGE_NAME:Install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! ./gradlew test ; then
    echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Install_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
