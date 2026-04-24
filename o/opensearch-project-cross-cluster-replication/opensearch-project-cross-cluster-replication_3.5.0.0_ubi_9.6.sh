#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cross-cluster-replication
# Version          : 3.5.0.0
# Source repo      : https://github.com/opensearch-project/cross-cluster-replication
# Tested on        : UBI:9.6
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shubhada Salunkhe <Shubhada.Salunkhe@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME=cross-cluster-replication
PACKAGE_URL=https://github.com/opensearch-project/cross-cluster-replication
SCRIPT_PACKAGE_VERSION="3.5.0.0"
PACKAGE_VERSION="${1:-$SCRIPT_PACKAGE_VERSION}"
OPENSEARCH_URL=https://github.com/opensearch-project/OpenSearch.git
OPENSEARCH_VERSION="${PACKAGE_VERSION::-2}"
OPENSEARCH_PACKAGE=OpenSearch
RUNTESTS=1
wdir="$(pwd)"
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

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

#--------------------------------
#Build opensearch-project
#--------------------------------
cd $wdir
git clone ${OPENSEARCH_URL}
cd ${OPENSEARCH_PACKAGE} && git checkout ${OPENSEARCH_VERSION}
./gradlew -p distribution/archives/linux-ppc64le-tar assemble

# ---------------------------
# Clone and Prepare Repository
# ---------------------------

cd $wdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply "$SCRIPT_DIR/opensearch-project-${PACKAGE_NAME}_${PACKAGE_VERSION}.patch"

# --------
# Build
# --------
ret=0
./gradlew clean assemble || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------$PACKAGE_NAME:Build_fails---------------------"
	exit 1
fi

# ---------------------------
# Skip Tests?
# ---------------------------
if [ "$RUNTESTS" -eq 0 ]; then
        set +ex
        echo "------------------ Complete: Build successful! Tests skipped. ------------------"
        exit 0
fi

# -----------------
# Test
# -----------------
ret=0
./gradlew test -x integTest || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------$PACKAGE_NAME::Test_fails-------------------------"
	exit 2
fi

set +ex
echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
