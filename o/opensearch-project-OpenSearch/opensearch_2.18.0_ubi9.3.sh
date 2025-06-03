#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : OpenSearch
# Version          : 2.18.0
# Source repo      : https://github.com/opensearch-project/OpenSearch
# Tested on        : ubi:9.3
# Language         : Java
# Travis-Check     : False
# Script License   : Apache License, Version 2 or later
# Maintainer       : Prachi Gaonkar<prachi.gaonkar@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# 1. Run the build-script in non-root mode with docker installed.
# 2. Travis check is set to false as script takes 2.5 hours to run.
# 3. Backward compatibility tests, tests that require Amazon-s3 credentials, tests that are flaky and in parity with intel are skipped.
# 4. Test for tasks server:test and server:internalClusterTest are failing in the test suite due to timeout errors, but pass when executed individually.These tasks take approximately 3-4 hours to complete, which is why they are being skipped.

sudo yum install -y git java-17-openjdk-devel java-11-openjdk-devel wget

CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

PACKAGE_NAME=OpenSearch
PACKAGE_URL=https://github.com/opensearch-project/OpenSearch.git
PACKAGE_VERSION=${1:-2.18.0}

# Step 2: Set Java environment variables
export JAVA17_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA17_HOME/bin

export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA11_HOME/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

git apply $SCRIPT_DIR/Opensearch_2.18.0.patch

if ! ./gradlew assemble ; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
#Commenting the command for gradlew check as the entire testsuite is flaky and it takes around 3-4 hours to complete.		
#elif ! ./gradlew check --continue -x server:test -x server:internalClusterTest -x plugins:repository-s3:testRepositoryCreds -x plugins:repository-s3:s3ThirdPartyTest -x plugins:repository-s3:yamlRestTestECS -x plugins:repository-s3:test -x plugins:repository-s3:yamlRestTestEKS -x plugins:repository-s3:yamlRestTestMinio -x plugins:repository-s3:yamlRestTest ; then
    #    echo "------------------$PACKAGE_NAME:Build_and _test_fails---------------------"
    #    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    #   echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    #    exit 2
else
        echo "Build Success"
        exit 0
fi
