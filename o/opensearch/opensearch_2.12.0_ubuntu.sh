#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : opensearch
# Version          : 2.12.0
# Source repo      : https://github.com/opensearch-project/opensearch
# Tested on        : ubuntu:20.04
# Language         : Java
# Travis-Check     : False
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# 1. Run the build-script in non-root mode.
# 2. Build wildfly image for v28.0.0-Final using Dockerfile: https://github.com/ppc64le/build-scripts/blob/72a9f309032343d656b2a473dba82cb25f2c7a8b/w/wildfly/Dockerfiles/27.0.0-ubi8/Dockerfile#L4
# 3. Travis check is set to false as script takes 2.5 hours to run.
# 4. Backward compatibility tests, tests that require Amazon-s3 and tests that are in parity with intel are skipped.

sudo apt install -y git openjdk-11-jdk wget docker docker-compose

CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

PACKAGE_NAME=opensearch
PACKAGE_URL=https://github.com/opensearch-project/opensearch
PACKAGE_VERSION=${1:-2.12.0}


git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

git apply $SCRIPT_DIR/Opensearch_2.12.0.diff

if ! ./gradlew assemble ; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
elif ! ./gradlew check -x test:fixtures:krb5kdc-fixture:postProcessFixture -x server:test -x client:rest-high-level:integTest   -x client:rest-high-level:asyncIntegTest -x plugins:repository-hdfs:secureHdfsFixture  -x plugins:repository-hdfs:integTestSecure -x plugins:repository-hdfs:secureHaHdfsFixture -x plugins:repository-hdfs:integTestSecureHa -x server:internalClusterTest -x plugins:repository-s3:testRepositoryCreds -x plugins:repository-s3:s3ThirdPartyTest -x plugins:repository-s3:yamlRestTestECS -x plugins:repository-s3:test -x plugins:repository-s3:yamlRestTestEKS -x plugins:repository-s3:yamlRestTestMinio -x plugins:repository-s3:yamlRestTest -x plugins:repository-azure:internalClusterTest -x plugins:repository-s3:test -x plugins:repository-azure:azureThirdPartyDefaultXmlTest ; then
        echo "------------------$PACKAGE_NAME:Build_and _test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 2
else
        echo "Build and Test Success"
        exit 0
fi

