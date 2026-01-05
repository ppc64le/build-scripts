#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 8.18.6
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : UBI: 9.6
# Ci-Check      : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Sanket Patil <Sanket.Patil11@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

SCRIPT_PACKAGE_VERSION=v8.18.6
PACKAGE_NAME=elasticsearch
PACKAGE_URL=https://github.com/elastic/elasticsearch.git
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
BUILD_DIR=$(pwd)
SCRIPT_PATH=$(dirname $(realpath $0))

# Install system dependencies (except Java)
yum install -y git gzip tar wget patch make gcc gcc-c++ libcurl-devel --allowerasing

wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.8_9.tar.gz
tar -xf OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.8_9.tar.gz -C /opt
rm -f OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.8_9.tar.gz

wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1+1/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.8.1_1.tar.gz
tar -xf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.8.1_1.tar.gz -C /opt
rm -f OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.8.1_1.tar.gz

wget https://github.com/adoptium/temurin18-binaries/releases/download/jdk-18.0.2.1%2B1/OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.2.1_1.tar.gz
tar -xf OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.2.1_1.tar.gz -C /opt
rm -f OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.2.1_1.tar.gz

wget https://github.com/adoptium/temurin19-binaries/releases/download/jdk-19.0.2%2B7/OpenJDK19U-jdk_ppc64le_linux_hotspot_19.0.2_7.tar.gz
tar -xf OpenJDK19U-jdk_ppc64le_linux_hotspot_19.0.2_7.tar.gz -C /opt
rm -f OpenJDK19U-jdk_ppc64le_linux_hotspot_19.0.2_7.tar.gz

wget https://github.com/adoptium/temurin20-binaries/releases/download/jdk-20%2B36/OpenJDK20U-jdk_ppc64le_linux_hotspot_20_36.tar.gz
tar -xf OpenJDK20U-jdk_ppc64le_linux_hotspot_20_36.tar.gz -C /opt
rm -f OpenJDK20U-jdk_ppc64le_linux_hotspot_20_36.tar.gz

wget https://github.com/adoptium/temurin22-binaries/releases/download/jdk-22.0.2%2B9/OpenJDK22U-jdk_ppc64le_linux_hotspot_22.0.2_9.tar.gz
tar -xf OpenJDK22U-jdk_ppc64le_linux_hotspot_22.0.2_9.tar.gz -C /opt
rm -f OpenJDK22U-jdk_ppc64le_linux_hotspot_22.0.2_9.tar.gz

wget https://github.com/adoptium/temurin23-binaries/releases/download/jdk-23.0.2%2B7/OpenJDK23U-jdk_ppc64le_linux_hotspot_23.0.2_7.tar.gz
tar -xf OpenJDK23U-jdk_ppc64le_linux_hotspot_23.0.2_7.tar.gz -C /opt
rm -f OpenJDK23U-jdk_ppc64le_linux_hotspot_23.0.2_7.tar.gz

wget https://github.com/adoptium/temurin24-binaries/releases/download/jdk-24.0.2%2B12/OpenJDK24U-jdk_ppc64le_linux_hotspot_24.0.2_12.tar.gz
tar -xf OpenJDK24U-jdk_ppc64le_linux_hotspot_24.0.2_12.tar.gz -C /opt
rm -f OpenJDK24U-jdk_ppc64le_linux_hotspot_24.0.2_12.tar.gz

# Set environment variables for Java
#export JAVA_HOME=/opt/jdk-21.0.2+13
export JAVA_HOME=/opt/jdk-21.0.8+9
export PATH=$JAVA_HOME/bin:$PATH
export LANG="en_US.UTF-8"
export ES_JAVA_HOME=$JAVA_HOME
export JDK17_HOME=/opt/jdk-17.0.8.1+1
export JDK17_HOME=/opt/jdk-18.0.2.1+1
export JDK19_HOME=/opt/jdk-19.0.2+7
export JDK20_HOME=/opt/jdk-20+36
export JDK22_HOME=/opt/jdk-22.0.2+9
export JDK23_HOME=/opt/jdk-23.0.2+7
export JDK24_HOME=/opt/jdk-24.0.2+12

echo "Using Java version: $(java --version)"

# Clone Elasticsearch repo
cd $BUILD_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Apply patch
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch

# Create required stub directories for ppc64le
mkdir -p distribution/archives/linux-ppc64le-tar
echo "// stub for ppc64le linux tar distribution" > distribution/archives/linux-ppc64le-tar/build.gradle

mkdir -p distribution/archives/oss-linux-ppc64le-tar
echo "// stub for ppc64le OSS linux tar distribution" > distribution/archives/oss-linux-ppc64le-tar/build.gradle

mkdir -p distribution/docker/cloud-ess-docker-ppc64le-export
echo "// stub for ppc64le cloud-ess docker export" > distribution/docker/cloud-ess-docker-ppc64le-export/build.gradle

# additional stubs
mkdir -p distribution/archives/no-jdk-darwin-ppc64le-tar
mkdir -p distribution/docker/ubi-docker-ppc64le-export
mkdir -p distribution/packages/ppc64le-deb
mkdir -p distribution/docker/ironbank-docker-ppc64le-export
mkdir -p distribution/docker/docker-ppc64le-export
mkdir -p distribution/packages/ppc64le-rpm
mkdir -p distribution/archives/darwin-ppc64le-tar
mkdir -p distribution/docker/cloud-docker-ppc64le-export

./gradlew :spotlessApply

# Build
./gradlew :distribution:archives:linux-tar:assemble --parallel --stacktrace

# Commenting out test part as tests are passing locally but not on Travis/GHA.
# Test (create non-root user for testing)

# useradd -m -s /bin/bash tester || true
# groupadd podman || true
# usermod -aG podman tester || true

# Give ownership of Elasticsearch source to tester
# chown -R tester:tester $BUILD_DIR/$PACKAGE_NAME || true

# Create required native lib directories (if not already present)
# mkdir -p $BUILD_DIR/$PACKAGE_NAME/libs/native/libraries/build/platform/linux-ppc64le
# mkdir -p $BUILD_DIR/$PACKAGE_NAME/lib/platform/linux-ppc64le

# if [ -f /usr/lib64/libzstd.so.1 ]; then
#    cp /usr/lib64/libzstd.so.1 $BUILD_DIR/$PACKAGE_NAME/libs/native/libraries/build/platform/linux-ppc64le/libzstd.so
#    cp /usr/lib64/libzstd.so.1 $BUILD_DIR/$PACKAGE_NAME/lib/platform/linux-ppc64le/libzstd.so
# fi

# Switch to tester user and run tests
# su - tester -c "
# set -e
# set -x
# cd $BUILD_DIR/$PACKAGE_NAME

# Ensure Java and Gradle paths are available for tester
# export JAVA_HOME=$JAVA_HOME
# export PATH=\$JAVA_HOME/bin:\$PATH
# export LANG=en_US.UTF-8

# echo 'Running Elasticsearch unit tests as non-root user...'

# Run tests but skip modules known to fail on ppc64le or unsupported as root
# ./gradlew test \
#     -x :x-pack:plugin:ml:test \
#     -x :x-pack:plugin:esql:test \
# 	-x :server:test \
#     --stacktrace -Dtests.haltonfailure=false

# ret=\$?
# if [ \$ret -ne 0 ]; then
#   echo 'ERROR: Elasticsearch tests failed.'
#   exit 2
# else
#   echo 'Elasticsearch tests passed successfully.'
# fi
# "
