#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package        : k-NN
# Version        : 2.19.2.0
# Source repo    : https://github.com/opensearch-project/k-NN
# Tested on      : UBI 9.3
# Language       : Java and C++
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer	   : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in non root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

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
PACKAGE_NAME=k-NN
PACKAGE_VERSION="2.19.2.0"
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

# ---------------------------
# Dependency Installation
# ---------------------------
sudo yum install -y git wget java-17-openjdk-devel python3-pip gcc gcc-c++ make git gcc-gfortran zlib-devel cmake
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin
sudo ln -sf /usr/bin/python3 /usr/bin/python

# ---------------------------
# Set up Git author identity
# ---------------------------
git config --global user.email "prachi.gaonkar@ibm.com"
git config --global user.name "prachi-gaonkar"

# ---------------------------
# Set the installation directory (e.g., $BUILD_HOME/local)
# ---------------------------
INSTALL_DIR="$BUILD_HOME/local"

# -------------------------------------------------------
# Build and install LAPACK
# -------------------------------------------------------
cd $BUILD_HOME
git clone https://github.com/Reference-LAPACK/lapack.git
cd lapack && git checkout v3.12.0
mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=$BUILD_HOME/local
make
make install

# -------------------------------------------------------
# Build and install OpenBLAS
# -------------------------------------------------------
cd $BUILD_HOME
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS && git checkout v0.3.28
make
make PREFIX=$INSTALL_DIR install NO_TEST=1

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd $BUILD_HOME
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
cd jni
cmake -DBLAS_INCLUDE_DIR=$BUILD_HOME/local/include -DLAPACK_LIBRARIES=$BUILD_HOME/local/lib64/liblapack.so -DBLAS_LIBRARIES=$BUILD_HOME/local/lib/libopenblas.so .

# ----------------------------------------------
# Apply patches to NMSLIB and FAISS
# ----------------------------------------------
cd external/nmslib
git apply ${SCRIPT_PATH}/$PACKAGE_NAME-nmslib-$PACKAGE_VERSION.patch
cd ../faiss/faiss
git apply ${SCRIPT_PATH}/$PACKAGE_NAME-faiss-$PACKAGE_VERSION.patch
cd $BUILD_HOME/$PACKAGE_NAME/jni
make
cp $BUILD_HOME/$PACKAGE_NAME/jni/release/libopensearchknn_faiss_avx512.so $BUILD_HOME/$PACKAGE_NAME/jni/release/libopensearchknn_faiss.so

# --------
# Build
# --------
cd $BUILD_HOME/$PACKAGE_NAME
ret=0
./gradlew build -x test -x integTest || ret=$?
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
        echo "------------------ Complete: Build and install successful! Tests skipped. ------------------"
        exit 0
fi
export OPENSEARCH_KNN_ZIP=${BUILD_HOME}/${PACKAGE_NAME}/build/distributions/opensearch-knn-${PACKAGE_VERSION}-SNAPSHOT.zip

# ----------------------------------------------
# Build opensearch tarball for integation tests
# ----------------------------------------------
cd $BUILD_HOME
git clone ${OPENSEARCH_URL}
cd ${OPENSEARCH_PACKAGE} && git checkout ${OPENSEARCH_VERSION}
./gradlew -p distribution/archives/linux-ppc64le-tar assemble

# ----------
# Unit Test
# ----------
cd $BUILD_HOME/$PACKAGE_NAME
ret=0
./gradlew test || ret=$?
if [ $ret -ne 0 ]; then
        ret=0
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Unit Test Failed ------------------"
	exit 2
fi

# -----------------
# Integration Test
# -----------------
ret=0
./gradlew integTest -PcustomDistributionUrl="$BUILD_HOME/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-${OPENSEARCH_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz" || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

set +ex
echo "Complete: Build and Tests successful!"
echo "Plugin zip available at [${OPENSEARCH_KNN_ZIP}]"
