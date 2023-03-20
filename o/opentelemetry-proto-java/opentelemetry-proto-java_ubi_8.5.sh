#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: opentelemetry-proto-java
# Version	: v0.18.0,v0.19.0
# Source repo	: https://github.com/open-telemetry/opentelemetry-proto-java
# Tested on	: ubi 8.5
# Language      : java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>, Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME="opentelemetry-proto-java"
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-proto-java"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD

# Default tag opentelemetry-proto-java
if [ -z "$1" ]; then
  export PACKAGE_VERSION="0.19.0"
else
  export PACKAGE_VERSION="$1"
fi

#installing required dependencies
echo "installing dependencies from system repo..."
dnf install -y git make gcc gcc-c++ java-17-openjdk-devel.ppc64le libtool file diffutils bc wget
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH
export GRPC_JAVA_VERSION="1.53.0"
export PROTOBUF_VERSION="3.19.4"

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout "v$PACKAGE_VERSION"

sed -i "s/\(grpcVersion = \).*/\1\"1\.53\.0\"/" build.gradle.kts
sed -i "s/mavenLocal/mavenCentral/" build.gradle.kts
sed -i "0,/mavenCentral/s/mavenCentral/mavenLocal/" build.gradle.kts


# building  and installing  protobuf from source
cd "$HOME_DIR"
git clone  https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v"$PROTOBUF_VERSION"
git submodule update --init
./autogen.sh
./configure
make -j"$(nproc)" 
make install

#building and installing grpc-java
cd "$HOME_DIR"
git clone https://github.com/grpc/grpc-java
cd grpc-java
git checkout v"$GRPC_JAVA_VERSION"

sed -i "s#powerpc64le-linux-gnu-##g" ./compiler/build.gradle ./compiler/check-artifact.sh ./buildscripts/kokoro/linux_artifacts.sh ./buildscripts/make_dependencies.sh
sed -i 's#white_list="linux-vdso64\\.so\\.1\\|libpthread\\.so\\.0\\|libm\\.so\\.6\\|libc\\.so\\.6\\|ld64\\.so\\.2"#white_list="linux-vdso64\\.so\\.1\\|libpthread\\.so\\.0\\|libm\\.so\\.6\\|libc\\.so\\.6\\|ld64\\.so\\.2\\|libstdc++\\.so\\.6\\|libgcc_s\\.so\\.1"#g' ./compiler/check-artifact.sh

sed -i "s#https://developers.google.com/protocol-buffers/docs/reference/java/#https://protobuf.dev/reference/java/api-docs/#g" ./protobuf/build.gradle

echo "org.gradle.daemon=true" >> gradle.properties
echo "org.gradle.configureondemand=true" >> gradle.properties
echo "org.gradle.jvmargs=-Xmx4g -XX:MetaspaceSize=2048m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" >> gradle.properties

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
	exit 2
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi

