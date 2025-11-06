#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : OpenSearch
# Version          : 3.2.0
# Source repo      : https://github.com/opensearch-project/OpenSearch.git
# Tested on        : UBI 9.6
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
# 2. Travis check is set to false as script takes 2-3 hours to run.
# 3. Backward compatibility tests, tests that require Amazon-s3 credentials, tests that are flaky and in parity with intel are skipped.
# 4.The Gradle tasks `server:test` and `server:internalClusterTest` take approximately 3–4 hours to complete. They are skipped by default but can be run separately if needed (see **README** for instructions).

PACKAGE_NAME=OpenSearch
PACKAGE_URL=https://github.com/opensearch-project/OpenSearch.git
PACKAGE_VERSION=${1:-3.2.0}
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

sudo yum install -y git java-17-openjdk-devel java-21-openjdk-devel wget
# Set Java environment variables
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin

export JAVA17_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA17_HOME/bin

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply $SCRIPT_DIR/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch

if ! ./gradlew -p distribution/archives/linux-ppc64le-tar assemble -x :distribution:docker:buildPpc64leDockerImage -x :distribution:docker:buildArm64DockerImage -x :distribution:docker:buildRiscv64DockerImage -x :distribution:docker:buildS390xDockerImage; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
 #elif ! ./gradlew check --continue -x server:test -x server:internalClusterTest -x plugins:repository-s3:testRepositoryCreds -x plugins:repository-s3:s3ThirdPartyTest   -x plugins:repository-s3:yamlRestTestECS   -x plugins:repository-s3:test   -x plugins:repository-s3:yamlRestTestEKS   -x plugins:repository-s3:yamlRestTestMinio   -x plugins:repository-s3:yamlRestTest --max-workers=1   --no-daemon   -Dorg.gradle.jvmargs="-Xmx6g --enable-native-access=ALL-UNNAMED" ; then
 #       echo "------------------$PACKAGE_NAME:Build_and _test_fails---------------------"
 #       echo "$PACKAGE_VERSION $PACKAGE_NAME"
 #      echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
 #       exit 2 
else
        echo "Build Success"
        exit 0
fi

echo "Skipping './gradlew check' because the full test suite is flaky and takes ~2–3 hours to complete."
echo "Please refer to the README for instructions on running specific tests separately."