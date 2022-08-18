#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: opentelemetry-proto-java
# Version	: v0.18.0
# Source repo	: https://github.com/open-telemetry/opentelemetry-proto-java
# Tested on	: ubi 8.5
# Language      : java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="opentelemetry-proto-java"
PACKAGE_VERSION=${1:-"0.18.0"}
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-proto-java"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD

echo "insstalling dependencies from system repo..."
dnf install -qy git make gcc-c++ java-17-openjdk-devel libtool file diffutils bc

echo "cloning..."
if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

cd $PACKAGE_NAME
git checkout v"$PACKAGE_VERSION"
export GRPC_JAVA_VERSION=$(grep -m1 grpcVersion build.gradle.kts | cut -d "=" -f 2 | sed "s/\"//g" | sed "s/\s//g")
export PROTOBUF_VERSION=$(grep -m1 protobufVersion build.gradle.kts | cut -d "=" -f 2 | sed "s/\"//g" | sed "s/\s//g")
IFS=. read -r major minor patch < <(echo "$GRPC_JAVA_VERSION")
if [ $(echo "$major.$minor<=1.44" | bc -l) -eq 1 ]; then
	sed -i "s/\(grpcVersion = \).*/\1\"1\.47\.0\"/" build.gradle.kts
	export GRPC_JAVA_VERSION="1.47.0"
fi

sed -i "s/mavenLocal/mavenCentral/" build.gradle.kts
sed -i "0,/mavenCentral/s/mavenCentral/mavenLocal/" build.gradle.kts

# building  and installing  protobuf from source
cd "$HOME_DIR"
git clone -q https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v"$PROTOBUF_VERSION"
git submodule update --init
./autogen.sh
./configure
make -j"$(nproc)" && make install

#building and installing grpc-java
cd "$HOME_DIR"
git clone -q https://github.com/grpc/grpc-java
cd grpc-java
git checkout v"$GRPC_JAVA_VERSION"
sed -i "s/checkArch \"\$FILE\"/#checkArch \"\$FILE\"/" ./compiler/check-artifact.sh
./gradlew publishToMavenLocal -PskipAndroid=true

cd "$HOME_DIR"/$PACKAGE_NAME
if ! ./gradlew -Prelease.version="$PACKAGE_VERSION" build; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! ./gradlew -Prelease.version="$PACKAGE_VERSION" test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
