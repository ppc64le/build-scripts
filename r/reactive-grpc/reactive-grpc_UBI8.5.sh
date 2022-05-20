#bin/bash
# ----------------------------------------------------------------------------
# Package       : Reactive-grpc
# Version       : Latest(Top of Tree)
# Source repo   : https://github.com/salesforce/reactive-grpc
# Tested on     : UBI
# Language      : C,C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pranav Pandit <pranav.pandit1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

HOME_DIR=/home

PACKAGE_NAME=reactive-grpc
PACKAGE_URL=https://github.com/salesforce/reactive-grpc.git

PACKAGE_PROTOBUF_NAME=protobuf
PACKAGE_PROTOBUF_VERSION=${1:-v3.17.2}
PACKAGE_PROTOBUF_URL=https://github.com/protocolbuffers/protobuf.git

PACKAGE_GRPC_JAVA_NAME=grpc-java
PACKAGE_GRPC_JAVA_VERSION=${1:-v1.42.1}
PACKAGE_GRPC_JAVA_URL=https://github.com/grpc/grpc-java.git

yum update -y
yum install -y maven git gcc-c++ automake autoconf libstdc++-static gzip wget libtool make

cd $HOME_DIR
#build Protocol buffers
if [ -d "$PACKAGE_PROTOBUF_NAME" ]; then
  echo "protobuf already present "
else
  git clone --recursive $PACKAGE_PROTOBUF_URL
fi
cd $PACKAGE_PROTOBUF_NAME && git checkout $PACKAGE_PROTOBUF_VERSION
./autogen.sh && cd protoc-artifacts && ./build-protoc.sh linux ppcle_64 protoc
cp target/linux/ppcle_64/protoc.exe /tmp
cd ..
sh autogen.sh
./configure
make && make install

cd $HOME_DIR
#build grpc-java
if [ -d "$PACKAGE_GRPC_JAVA_NAME" ]; then
  echo "grpc-java already present "
else
  git clone --recursive $PACKAGE_GRPC_JAVA_URL
fi
cd $PACKAGE_GRPC_JAVA_NAME && git checkout $PACKAGE_GRPC_JAVA_VERSION && ./gradlew build -PskipAndroid=true

cd $HOME_DIR
#build reactive-grpc
cp grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java /tmp

if [ -d "$PACKAGE_NAME" ]; then
  echo "reactive-grpc already present "
else
  git clone --recursive $PACKAGE_URL
fi

cd $PACKAGE_NAME
mvn install:install-file -DgroupId=io.grpc -DartifactId=protoc-gen-grpc-java -Dversion=1.42.1 -Dclassifier=linux-ppcle_64 -Dpackaging=exe -Dfile=/tmp/protoc-gen-grpc-java
mvn install -DSkipTests=true
mvn test
