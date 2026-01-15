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

# ---------------------------
# Configuratio
# ---------------------------

PACKAGE_NAME=user-behavior-insights
PACKAGE_URL=https://github.com/opensearch-project/user-behavior-insights
SCRIPT_PACKAGE_VERSION="3.3.0.0"
PACKAGE_VERSION="${1:-$SCRIPT_PACKAGE_VERSION}"
OPENSEARCH_VERSION="${PACKAGE_VERSION::-2}"
OPENSEARCH_PACKAGE="OpenSearch"
RUNTESTS=1
wdir="$(pwd)"

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

sudo yum install -y git java-21-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin

sudo chown -R test_user:test_user /home/tester

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

# ---------------------------
# Clone and Prepare Repository
# ---------------------------

cd $wdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME && git checkout $PACKAGE_VERSION



# --------
# Build
# --------
ret=0
./gradlew build || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
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
./gradlew test  || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

set +ex
echo "Complete: Build and Tests successful!"
