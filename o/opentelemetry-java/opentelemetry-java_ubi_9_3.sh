#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : opentelemetry-java
# Version       : v1.38.0
# Source repo   : https://github.com/open-telemetry/opentelemetry-java
# Tested on     : ubi: 9.3
# Language      : java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME="opentelemetry-java"
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-java"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD

# Default tag opentelemetry-java
if [ -z "$1" ]; then
  export PACKAGE_VERSION="v1.38.0"
else
  export PACKAGE_VERSION="$1"
fi


#installing required dependencies
echo "installing dependencies from system repo..."
dnf install -y git make gcc gcc-c++ java-17-openjdk-devel.ppc64le  libtool file diffutils bc wget initscripts
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH
export GRPC_JAVA_VERSION="1.63.0"
export PROTOBUF_VERSION="21.12"

# Check if Docker is installed
if which docker >/dev/null 2>&1; then
    # Docker is installed, so remove it
    echo "Docker is installed inside the container. Removing Docker..."
    service docker stop
else
    # Docker is not installed, execute the rest of the script here
    echo "Docker is not installed inside the container. Continue with the rest of the script."
    # Place the remaining commands of your script here
fi


echo "cloning..."

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
      rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Removed existing package if any"
fi

cd $HOME_DIR
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION"

sed -i "s/mavenLocal/mavenCentral/" settings.gradle.kts
sed -i "0,/mavenCentral/s/mavenCentral/mavenLocal/" settings.gradle.kts

cd "$HOME_DIR"

#installing grpc-java
curl -LO https://github.com/grpc/grpc-java/archive/refs/tags/v${GRPC_JAVA_VERSION}.tar.gz
tar xzf v${GRPC_JAVA_VERSION}.tar.gz
rm -rf v${GRPC_JAVA_VERSION}.tar.gz
cd grpc-java-${GRPC_JAVA_VERSION}

sed -i "s#powerpc64le-linux-gnu-##g" ./compiler/build.gradle ./compiler/check-artifact.sh ./buildscripts/kokoro/linux_artifacts.sh ./buildscripts/make_dependencies.sh
sed -i 's#white_list="linux-vdso64\\.so\\.1\\|libpthread\\.so\\.0\\|libm\\.so\\.6\\|libc\\.so\\.6\\|ld64\\.so\\.2"#white_list="linux-vdso64\\.so\\.1\\|libpthread\\.so\\.0\\|libm\\.so\\.6\\|libc\\.so\\.6\\|ld64\\.so\\.2\\|libstdc++\\.so\\.6\\|libgcc_s\\.so\\.1"#g' ./compiler/check-artifact.sh

sed -i "s#https://developers.google.com/protocol-buffers/docs/reference/java/#https://protobuf.dev/reference/java/api-docs/#g" ./protobuf/build.gradle

echo "org.gradle.daemon=true" >> gradle.properties
echo "org.gradle.configureondemand=true" >> gradle.properties
echo "org.gradle.jvmargs=-Xmx4g -XX:MetaspaceSize=2048m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" >> gradle.properties


#installing and building protobuf
curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOBUF_VERSION/protobuf-all-$PROTOBUF_VERSION.tar.gz
tar xzf protobuf-all-$PROTOBUF_VERSION.tar.gz --no-same-owner
cd protobuf-$PROTOBUF_VERSION
./configure --disable-shared
make -j$(nproc)
make install
cd ../

#building grpc-java
./gradlew build -x test -PskipAndroid=true
./gradlew java_pluginExecutable -PskipAndroid=true
./gradlew publishToMavenLocal -PskipAndroid=true


#building and testing opentelemetry-java
cd "$HOME_DIR"/$PACKAGE_NAME

#building opentelemetry java
if ! ./gradlew build -x test; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi

#testing opentelemetry-java

#Skipping 2 tests.
#exporters:prometheus:test ---> this test requires ipv6 container which is not allowed in currency infrastructure as of now. So skipping it.
#exporters:common:test ---> this test is flaky which is failing on x86 and ppc64le, so skipping it.

if ! ./gradlew test -x exporters:common:test -x exporters:prometheus:test; then
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