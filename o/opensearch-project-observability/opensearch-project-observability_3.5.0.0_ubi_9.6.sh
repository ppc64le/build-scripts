#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package        : observability
# Version        : 3.5.0.0
# Source repo    : https://github.com/opensearch-project/observability
# Tested on      : UBI 9.6
# Language       : Java
# Ci-Check       : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Shubhada Salunkhe <Shubhada.Salunkhe@ibm.com>
#
# Disclaimer     : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# -------------------
# Configuration
# -------------------
PACKAGE_NAME="observability"
PACKAGE_URL="https://github.com/opensearch-project/observability"
SCRIPT_PACKAGE_VERSION="3.5.0.0"
PACKAGE_VERSION="${1:-$SCRIPT_PACKAGE_VERSION}"

OPENSEARCH_VERSION="${PACKAGE_VERSION::-2}"
RUNTESTS=1
wdir="$(pwd)"
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

# -------------------
# Parse CLI Arguments (KEEPING YOUR LOOP)
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
# Setup Maven local repo safely
# ---------------------------
mkdir -p ~/.m2/repository

# =========================================================
# 1. Build OpenSearch (REQUIRED for plugins)
# =========================================================
cd $wdir
git clone https://github.com/opensearch-project/OpenSearch.git
cd OpenSearch
git checkout $OPENSEARCH_VERSION

./gradlew :distribution:archives:linux-ppc64le-tar:assemble
./gradlew publishToMavenLocal
./gradlew :build-tools:publishToMavenLocal

# =========================================================
# 2. Build common-utils dependency
# =========================================================
cd $wdir
git clone https://github.com/opensearch-project/common-utils.git
cd common-utils
git checkout $PACKAGE_VERSION
git apply ${SCRIPT_DIR}/common-utils_${PACKAGE_VERSION}.patch
./gradlew assemble
./gradlew publishToMavenLocal

# =========================================================
# 3. Build Observability plugin
# =========================================================
cd $wdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply "${SCRIPT_DIR}/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch"
 
ret=0
# ---------------- Build ----------------
./gradlew clean assemble || ret=$?

if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
fi

export OBSERVABILITY_ZIP=${wdir}/${PACKAGE_NAME}/build/distributions/observability-${PACKAGE_VERSION}.zip

# ---------------- Skip Tests ----------------
if [ "$RUNTESTS" -eq 0 ]; then
  echo "Build successful. Tests skipped."
  exit 0
fi

ret=0
# ---------------- Tests ----------------
./gradlew test -Dbuild.snapshot=false || ret=$?

if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}:Tests Failed ------------------"
	exit 2
fi
set +ex
echo "Build + Tests SUCCESS for observability ${PACKAGE_VERSION}"
echo "Plugin zip available at [${OBSERVABILITY_ZIP}]"

