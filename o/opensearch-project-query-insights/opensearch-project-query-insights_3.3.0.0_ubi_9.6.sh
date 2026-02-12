#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : query-insights
# Version          : 3.3.0.0
# Source repo      : https://github.com/opensearch-project/query-insights
# Tested on        : UBI 9.6
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
# Configuration
# ---------------------------

PACKAGE_NAME="query-insights"
PACKAGE_ORG="opensearch-project"
SCRIPT_PACKAGE_VERSION="3.3.0.0"
PACKAGE_VERSION="${1:-$SCRIPT_PACKAGE_VERSION}"
OPENSEARCH_VERSION="${PACKAGE_VERSION::-2}"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
COMMON_UTILS_VERSION="3.2.0.0"
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

# ------------------------------
# Build common-utils
# ------------------------------
cd $wdir
git clone https://github.com/opensearch-project/common-utils.git
cd common-utils
git checkout "${COMMON_UTILS_VERSION}"
./gradlew assemble
./gradlew -Prelease=true publishToMavenLocal

#------------------
# build security 
#--------------------
cd $wdir
git clone https://github.com/opensearch-project/security.git
cd security
git checkout "${PACKAGE_VERSION}"
git apply $SCRIPT_DIR/security_${SCRIPT_PACKAGE_VERSION}.patch
./gradlew clean assemble
./gradlew -Prelease=true publishToMavenLocal


# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd $wdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME && git checkout $PACKAGE_VERSION
git apply $SCRIPT_DIR/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch



# --------
# Build
# --------
ret=0
./gradlew build -x test -x integTest -PcustomDistributionUrl=$wdir/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-$OPENSEARCH_VERSION-SNAPSHOT-linux-ppc64le.tar.gz       -Dbuild.snapshot=false   -PlocalSecurityPluginZip=file://$wdir/security/build/distributions/opensearch-security-$PACKAGE_VERSION.zip || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
fi


# ---------------------------
# Skip Tests?
# ---------------------------
if [ "$RUN_TESTS" -eq 0 ]; then
        set +ex
        echo "------------------ Complete: Build and install successful! Tests skipped. ------------------"
        exit 0
fi

# ----------
# Test
# ----------
ret=0
    ./gradlew test   -PcustomDistributionUrl=$wdir/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-$OPENSEARCH_VERSION-SNAPSHOT-linux-ppc64le.tar.gz       -Dbuild.snapshot=false   -PlocalSecurityPluginZip=file://$wdir/security/build/distributions/opensearch-security-$PACKAGE_VERSION.zip || ret=$? 
    if [ $ret -ne 0 ]; then
		set +ex
		echo "------------------ ${PACKAGE_NAME}: Test Failed ------------------"
		exit 2
	fi

set +ex
echo "Complete: Build and Tests successful!"
