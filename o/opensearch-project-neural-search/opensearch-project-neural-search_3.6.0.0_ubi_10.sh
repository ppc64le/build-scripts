#!/bin/bash -ex
# --------------------------------------------------------------------------------
# Package        : neural-search
# Version        : 3.6.0.0
# Source repo    : https://github.com/opensearch-project/neural-search
# Tested on      : UBI 10
# Language       : Java
# Ci-Check       : false
# Maintainer     : Shubhada Salunkhe <shubhada.salunkhe@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in non root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
#
# Note         : Gradle wrapper upgraded from 9.2.0 to 9.6.1 to support Java 25.
#
# CVE Fix      : CVE-2026-40542 - httpclient5 upgraded from 5.6 to 5.6.1
#                Applied inline via Python in build.gradle:
#                  1. buildscript configurations.all resolutionStrategy
#                  2. allprojects configurations.all resolutionStrategy
# --------------------------------------------------------------------------------

# ---------------------------
# Check for root user
# ---------------------------
if ! ((${EUID:-0} || "$(id -u)")); then
        set +ex
        echo "FAIL: This script must be run as a non-root user with sudo permissions"
        exit 3
fi

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="neural-search"
PACKAGE_ORG="opensearch-project"
SCRIPT_PACKAGE_VERSION="3.6.0.0"
PACKAGE_VERSION="${1:-$SCRIPT_PACKAGE_VERSION}"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
OPENSEARCH_VERSION="${PACKAGE_VERSION::-2}"
OPENSEARCH_PACKAGE="OpenSearch"
OPENSEARCH_URL=https://github.com/${PACKAGE_ORG}/${OPENSEARCH_PACKAGE}.git
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
sudo chown -R test_user:test_user /home/tester
sudo yum install -y git wget sudo unzip make cmake gcc gcc-c++ perl python3-devel python3-pip java-25-openjdk-devel
export JAVA_HOME=$(ls -d /usr/lib/jvm/java-25-openjdk* 2>/dev/null | head -1)
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

# ----------------------------------------------
# Build OpenSearch tarball for integration tests
# ----------------------------------------------
cd $BUILD_HOME
git clone ${OPENSEARCH_URL}
cd ${OPENSEARCH_PACKAGE} && git checkout ${OPENSEARCH_VERSION}
sed -i 's|gradle-9.2.0-all.zip|gradle-9.6.1-all.zip|g' gradle/wrapper/gradle-wrapper.properties
sed -i '/distributionSha256Sum/d' gradle/wrapper/gradle-wrapper.properties
./gradlew --no-daemon -p distribution/archives/linux-ppc64le-tar assemble

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd $BUILD_HOME
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout $PACKAGE_VERSION

# ----------------------------
# Upgrade Gradle wrapper to 9.6.1 for Java 25 support
# (sed directly — Gradle 9.2.0 cannot run under Java 25 to self-upgrade)
# ----------------------------
sed -i 's|gradle-9.2.0-all.zip|gradle-9.6.1-all.zip|g' gradle/wrapper/gradle-wrapper.properties
sed -i '/distributionSha256Sum/d' gradle/wrapper/gradle-wrapper.properties

# ----------------------------
# Apply CVE Fix: CVE-2026-40542
# Forces httpclient5 to 5.6.1 in:
#   1. buildscript configurations.all resolutionStrategy
#   2. allprojects configurations.all resolutionStrategy
# ----------------------------
python3 - <<'EOF'
import sys

content = open('build.gradle').read()

# Fix 1: inside buildscript configurations.all resolutionStrategy
old1 = 'force("org.eclipse.platform:org.eclipse.core.resources:4.20.0") // CVE for < 4.20'
new1 = old1 + '\n                force("org.apache.httpcomponents.client5:httpclient5:5.6.1") // CVE-2026-40542'
if old1 not in content:
    print("ERROR: Could not find buildscript resolutionStrategy anchor in build.gradle")
    sys.exit(1)
content = content.replace(old1, new1, 1)

# Fix 2: inside allprojects configurations.all resolutionStrategy
old2 = 'force("com.google.errorprone:error_prone_annotations:2.21.1")'
new2 = old2 + '\n            force("org.apache.httpcomponents.client5:httpclient5:5.6.1") // CVE-2026-40542'
if old2 not in content:
    print("ERROR: Could not find allprojects resolutionStrategy anchor in build.gradle")
    sys.exit(1)
content = content.replace(old2, new2, 1)

open('build.gradle', 'w').write(content)
print("CVE-2026-40542 fix applied successfully to build.gradle")
EOF

# Verify both fixes are present
echo "Verifying CVE fix..."
grep -n "httpclient5" build.gradle

# --------
# Build
# --------
ret=0
./gradlew build -x test -x integTest -Dbuild.snapshot=false || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
        exit 1
fi

# --------
# Install
# --------
./gradlew -Prelease=true publishToMavenLocal -Dbuild.snapshot=false

# ---------------------------
# Skip Tests?
# ---------------------------
if [ "$RUNTESTS" -eq 0 ]; then
        set +ex
        echo "------------------ Complete: Build and install successful! Tests skipped. ------------------"
        exit 0
fi

# ----------
# Unit Test
# ----------
ret=0
./gradlew test -x integTest --continue -Dbuild.snapshot=false || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Unit Test Failed ------------------"
        exit 2
fi

# -----------------
# Integration Test
# -----------------
ret=0
./gradlew integTest \
  -PcustomDistributionUrl=$BUILD_HOME/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-${OPENSEARCH_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz \
  -Dbuild.snapshot=false || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
        exit 2
fi

set +ex
echo "------------------ Complete: Build and Tests successful! ------------------"
