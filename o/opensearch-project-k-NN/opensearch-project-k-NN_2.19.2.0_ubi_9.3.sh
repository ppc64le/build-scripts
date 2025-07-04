#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package        : k-NN
# Version        : 2.19.2.0
# Source repo    : https://github.com/opensearch-project/k-NN
# Tested on      : UBI 9.3
# Language       : Java and C++
# Travis-Check   : False
# Script License : Apache License, Version 2 or later
# Maintainer	 : Prachi Gaonkar <prachi.gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in non root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=k-NN
PACKAGE_VERSION=${1:-2.19.2.0}
PACKAGE_URL=https://github.com/opensearch-project/${PACKAGE_NAME}.git
OPENSEARCH_VERSION=${PACKAGE_VERSION::-2}
OPENSEARCH_PACKAGE=OpenSearch
OPENSEARCH_URL=https://github.com/opensearch-project/${OPENSEARCH_PACKAGE}.git
wdir=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

# Install required packages
sudo yum install -y git wget cmake java-21-openjdk-devel python3-pip gcc gcc-c++ make git gcc-gfortran zlib-devel

git config --global user.email "prachi.gaonkar@ibm.com"
git config --global user.name "prachi-gaonkar"

#Set Java environment variables
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Set the installation directory (e.g., $HOME/local)
INSTALL_DIR="$wdir/local"

# Clone and build LAPACK
git clone https://github.com/Reference-LAPACK/lapack.git
cd lapack && git checkout v3.12.0
mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=$HOME/local
make
make install
cd ../..

# Clone and build OpenBLAS
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS && git checkout v0.3.28
make
make PREFIX=$INSTALL_DIR install
cd ..

#Clone and build k-NN
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
cd jni
cmake -DBLAS_INCLUDE_DIR=$HOME/local/include -DLAPACK_LIBRARIES=$HOME/local/lib64/liblapack.so -DBLAS_LIBRARIES=$HOME/local/lib/libopenblas.so .

# Apply patches to NMSLIB and FAISS
cd external/nmslib
git apply $SCRIPT_DIR/${PACKAGE_NAME}-nmslib-${PACKAGE_VERSION}.patch
cd ../faiss/faiss
git apply $SCRIPT_DIR/${PACKAGE_NAME}-faiss-${PACKAGE_VERSION}.patch
cd ../../../
make

# Build OpenSearch
cd $wdir
git clone ${OPENSEARCH_URL}
cd ${OPENSEARCH_PACKAGE} && git checkout ${OPENSEARCH_VERSION}
git apply $SCRIPT_DIR/${OPENSEARCH_PACKAGE}_${OPENSEARCH_VERSION}.patch
./gradlew -p distribution/archives/linux-ppc64le-tar assemble

#Build k-NN with OpenSearch distribution installed locally and run tests
cd $wdir/k-NN
cp $wdir/k-NN/jni/release/libopensearchknn_faiss_avx512.so $wdir/k-NN/jni/release/libopensearchknn_faiss.so

#Invoke Build with Unit and Integration tests with locally installed Opensearch distribution for ppc64le 
if ! ./gradlew build -PcustomDistributionUrl="$wdir/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-${OPENSEARCH_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz"; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
elif ! ./gradlew test; then
    echo "------------------$PACKAGE_NAME::Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Test_fails"
    exit 2
else
	# If both the build and test are successful, print the success message
	echo "------------------$PACKAGE_NAME:: Build_and_Test_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
	exit 0
fi

