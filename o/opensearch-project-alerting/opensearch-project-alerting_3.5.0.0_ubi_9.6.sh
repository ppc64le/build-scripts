#!/bin/bash -e
# --------------------------------------------------------------------------------
# Package        : alerting 
# --------------------------------------------------------------------------------
# Version        : 3.5.0.0
# Source repo    : https://github.com/opensearch-project/alerting
# Tested on      : UBI 9.6
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer     : Shubhada Salunkhe <Shubhada.salunkhe@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# --------------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="alerting"
PACKAGE_ORG="opensearch-project"
PACKAGE_VERSION="3.5.0.0"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
SCRIPT_PATH=$(dirname $(realpath $0))
RUNTESTS=1
BUILD_HOME="$(pwd)"

# -------------------
# Parse CLI Arguments
# -------------------
for i in "$@"; do
  case $i in
    --skip-tests)
      RUNTESTS=0
      echo "Skipping tests"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 3
      ;;
    *)
      PACKAGE_VERSION=$i
      echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"
      ;;
  esac
done


# ---------------------------
# Dependency Installation
# ---------------------------
sudo yum install -y git wget gcc gcc-c++ make cmake \
 python3 python3-devel \
 openssl-devel bzip2-devel zlib-devel \
 java-25-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-25-openjdk
export PATH=$JAVA_HOME/bin:$PATH

sudo chown -R test_user:test_user /home/tester

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

git apply ${SCRIPT_PATH}/${PACKAGE_ORG}-${PACKAGE_NAME}_${PACKAGE_VERSION}.patch

# --------
# Build
# --------
ret=0
./gradlew clean assemble || ret=$?
if [ $ret -ne 0 ]; then
    set +ex
    echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi

export OPENSEARCH_ALERTING_ZIP=${BUILD_HOME}/${PACKAGE_NAME}/alerting/build/distributions/opensearch-alerting-3.5.0.0-SNAPSHOT.zip

# ---------------------------
# Skip Tests?
# ---------------------------
if [ "$RUNTESTS" -eq 0 ]; then
    set +ex
    echo "------------------ Complete: Build successful! Tests skipped ------------------"
    exit 0
fi

# ----------
# Unit Test
# ----------
ret=0
env -i PATH=/usr/bin:/bin JAVA_HOME=$JAVA_HOME ./gradlew test \
    -x :alerting:compileKotlin \
    -x :alerting:compileTestKotlin || ret=$?

if [ $ret -ne 0 ]; then
    set +ex
    echo "------------------ ${PACKAGE_NAME}: Unit Test Failed ------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Unit_Test_Fails"
    exit 2
fi


# ---------------------------
# Success
# ---------------------------
set +ex
echo "Complete: Build and Tests successful!"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
echo "Plugin zip available at [${OPENSEARCH_ALERTING_ZIP}]"

