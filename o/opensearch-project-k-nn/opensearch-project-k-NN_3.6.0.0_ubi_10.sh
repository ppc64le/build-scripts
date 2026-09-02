#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package        : k-NN
# Version        : 3.6.0.0
# Source repo    : https://github.com/opensearch-project/k-NN.git
# Tested on      : UBI 10
# Language       : Java and C++
# Ci-Check       : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Shubhada Salunkhe <shubhada.salunkhe@ibm.com>
#
# Disclaimer: This script has been tested in non root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# CVE Fix      : CVE-2026-40542 - httpclient5 upgraded from 5.6 to 5.6.1
#                Applied inline via Python in build.gradle:
#                  1. buildscript resolutionStrategy
#                  2. allprojects configurations.all resolutionStrategy
#
# ----------------------------------------------------------------------------

# ----------------------------
# Configuration
# ----------------------------
PACKAGE_NAME=k-NN
SCRIPT_PACKAGE_VERSION="3.6.0.0"
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/opensearch-project/${PACKAGE_NAME}.git
OPENSEARCH_VERSION=${PACKAGE_VERSION::-2}
OPENSEARCH_PACKAGE=OpenSearch
OPENSEARCH_URL=https://github.com/opensearch-project/${OPENSEARCH_PACKAGE}.git
RUNTESTS=1
BUILD_HOME=`pwd`
SCRIPT_PATH=$(dirname $(realpath $0))

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

# ------------------------------
# Dependency Installation
# ------------------------------
sudo chown -R test_user:test_user /home/tester
sudo yum install -y git wget python3-pip gcc gcc-c++ make cmake gcc-gfortran zlib zlib-devel openblas openblas-devel libomp java-25-openjdk-devel
export JAVA_HOME=$(ls -d /usr/lib/jvm/java-25-openjdk* 2>/dev/null | head -1)
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

sudo ln -sf /usr/bin/python3 /usr/bin/python
sudo pip install cmake==3.24.0

# ---------------------------------------------------------------------------
# Configure dummy Git identity
# (Required to prevent 'committer identity unknown' errors during patching)
# ---------------------------------------------------------------------------
git config --global user.name "build-bot"
git config --global user.email "build-bot@example.com"

# -------------------------------------------------------
# Set the installation directory (e.g., $BUILD_HOME/local)
# -------------------------------------------------------
INSTALL_DIR="$BUILD_HOME/local"

# -------------------------------------------------------
# Build and install LAPACK
# -------------------------------------------------------
cd $BUILD_HOME
git clone https://github.com/Reference-LAPACK/lapack.git
cd lapack && git checkout v3.12.1
mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=$BUILD_HOME/local
make
make install

# ----------------------------
# Clone and Prepare Repository
# ----------------------------
cd $BUILD_HOME
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}

# ----------------------------
# Apply CVE Fix: CVE-2026-40542
# Forces httpclient5 to 5.6.1 in:
#   1. buildscript resolutionStrategy
#   2. allprojects configurations.all resolutionStrategy
# Applied inline via Python to avoid git apply line-number issues
# ----------------------------
python3 - <<'EOF'
import sys

content = open('build.gradle').read()

# Fix 1: inside buildscript resolutionStrategy
old1 = 'force("org.eclipse.platform:org.eclipse.core.resources:4.20.0") // CVE for < 4.20'
new1 = old1 + '\n                force("org.apache.httpcomponents.client5:httpclient5:5.6.1") // CVE-2026-40542'
if old1 not in content:
    print("ERROR: Could not find buildscript resolutionStrategy anchor in build.gradle")
    sys.exit(1)
content = content.replace(old1, new1, 1)

# Fix 2: inside allprojects block, after java { } section
# Insert configurations.all block after line containing targetCompatibility = JavaVersion.VERSION_21
lines = content.splitlines(keepends=True)
insert = (
    '    configurations.all {\n'
    '        resolutionStrategy {\n'
    '            force("org.apache.httpcomponents.client5:httpclient5:5.6.1") // CVE-2026-40542\n'
    '        }\n'
    '    }\n'
)
idx = None
for i, line in enumerate(lines):
    if 'targetCompatibility = JavaVersion.VERSION_21' in line:
        # insert after the closing brace of java { } block (next line with just '    }')
        for j in range(i+1, len(lines)):
            if lines[j].strip() == '}':
                idx = j + 1
                break
        break
if idx is None:
    print("ERROR: Could not find targetCompatibility anchor in build.gradle")
    sys.exit(1)
lines.insert(idx, insert)
open('build.gradle', 'w').writelines(lines)
print("CVE-2026-40542 fix applied successfully to build.gradle")
EOF

# Verify both fixes are present
echo "Verifying CVE fix..."
grep -n "httpclient5" build.gradle

cd jni
cmake -DBLAS_INCLUDE_DIR=$BUILD_HOME/local/include \
      -DLAPACK_LIBRARIES=$BUILD_HOME/local/lib64/liblapack.so \
      -DBLAS_LIBRARIES=/usr/lib64/libopenblas.so .

# ----------------------------------------------
# Apply patches to NMSLIB and FAISS
# ----------------------------------------------
cd external/nmslib
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}-nmslib-${SCRIPT_PACKAGE_VERSION}.patch
cd ../faiss/faiss
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}-faiss-${SCRIPT_PACKAGE_VERSION}.patch
cd $BUILD_HOME/$PACKAGE_NAME/jni
rm -rf build CMakeFiles CMakeCache.txt
make

# ----------------------------------------------
# Build opensearch tarball for integration tests
# ----------------------------------------------
cd $BUILD_HOME
git clone ${OPENSEARCH_URL}
cd ${OPENSEARCH_PACKAGE} && git checkout ${OPENSEARCH_VERSION}
./gradlew -p distribution/archives/linux-ppc64le-tar assemble
./gradlew -Prelease=true publishToMavenLocal
./gradlew :build-tools:publishToMavenLocal

# --------
# Build
# --------
cd $BUILD_HOME/$PACKAGE_NAME
ret=0
./gradlew build assemble \
  -x test -x integTest \
  -Dbuild.lib.commit_patches=false \
  -PcustomDistributionUrl=$BUILD_HOME/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-${OPENSEARCH_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz \
  -Dbuild.snapshot=false \
  --console=plain || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
        exit 1
fi
export OPENSEARCH_KNN_ZIP=${BUILD_HOME}/${PACKAGE_NAME}/build/distributions/opensearch-knn-${PACKAGE_VERSION}-SNAPSHOT.zip

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
# NOTE: Unit tests that depend on native JNI libraries (opensearchknn_faiss,
# opensearchknn_common, opensearchknn_nmslib) will fail on ppc64le due to
# AVX512+FP16 SIMD not being supported by the compiler on this architecture.
# This is a known environment limitation and not a code issue.
# JNI-independent Java unit tests will pass.
cd $BUILD_HOME/$PACKAGE_NAME
ret=0
./gradlew test \
  --max-workers=1 \
  -Dbuild.snapshot=false \
  --console=plain || ret=$?
if [ $ret -ne 0 ]; then
        ret=0
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Unit Test Failed (known JNI limitation on ppc64le) ------------------"
        exit 2
fi

# ------------------
# Integration Test
# ------------------
# NOTE: Integration tests also require native JNI libraries and may fail
# on ppc64le for the same reason as unit tests above.
ret=0
./gradlew integTest \
  -PcustomDistributionUrl="$BUILD_HOME/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-${OPENSEARCH_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz" \
  -Dbuild.snapshot=false \
  --console=plain || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Integration Test Failed (known JNI limitation on ppc64le) ------------------"
        exit 2
fi

set +ex
echo "Complete: Build and Tests successful!"
echo "Plugin zip available at [${OPENSEARCH_KNN_ZIP}]"
