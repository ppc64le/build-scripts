#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : OpenSearch
# Version          : 3.2.0
# Source repo      : https://github.com/opensearch-project/OpenSearch.git
# Tested on        : UBI 9.6
# Language         : Java
# Ci-Check         : True
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
# 3. Backward compatibility tests, tests that require Amazon-s3 credentials, tests that are flaky and in parity with intel are skipped.
# 4. The complete test suite is flaky and takes ~2–3 hours to complete. Hence, it is skipped.
#    Please refer to the README for instructions on running specific tests separately.

# ---------------------------
# Check for root user
# ---------------------------
yum install sudo -y
#if [ "$(id -u)" -eq 0 ]; then
#  echo "ERROR: This script must be run as a non-root user with sudo permissions"
#  exit 1
#fi


# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME=OpenSearch
PACKAGE_URL=https://github.com/opensearch-project/OpenSearch.git
SCRIPT_PACKAGE_VERSION="3.2.0"
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
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
git apply $SCRIPT_DIR/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch

# --------
# Build/assemble
# --------
ret=0
./gradlew -p distribution/archives/linux-ppc64le-tar assemble -x :distribution:docker:buildPpc64leDockerImage -x :distribution:docker:buildArm64DockerImage -x :distribution:docker:buildRiscv64DockerImage -x :distribution:docker:buildS390xDockerImage || ret=$?   
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
fi

# ----------
# Tests
# ----------
#ret=0
#./gradlew check --continue -x server:test -x server:internalClusterTest -x plugins:repository-s3:testRepositoryCreds -x plugins:repository-s3:s3ThirdPartyTest   -x plugins:repository-s3:yamlRestTestECS   -x plugins:repository-s3:test   -x plugins:repository-s3:yamlRestTestEKS   -x plugins:repository-s3:yamlRestTestMinio   -x plugins:repository-s3:yamlRestTest --max-workers=1   --no-daemon   -Dorg.gradle.jvmargs="-Xmx6g --enable-native-access=ALL-UNNAMED" || ret=$?   
#if [ $ret -ne 0 ]; then
#		set +ex
#		echo "------------------ ${PACKAGE_NAME}: Unit Test Failed ------------------"
#		exit 2
#fi

echo "Skipping './gradlew check' because the full test suite is flaky and takes ~2–3 hours to complete."
echo "Please refer to the README for instructions on running specific tests separately."