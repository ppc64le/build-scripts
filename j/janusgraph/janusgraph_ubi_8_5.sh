#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : JanusGraph
# Version       : 0.6.2
# Source repo   : https://github.com/JanusGraph/janusgraph.git
# Tested on     : ubi8.5
# Language      : java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti.Wali@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=janusgraph
PACKAGE_URL=https://github.com/JanusGraph/janusgraph.git
VERSION=${1:-0.6.2}

yum install -y maven git wget gcc-c++ make autoconf which diffutils
cd ~
wget https://github.com/protocolbuffers/protobuf/releases/download/v21.5/protobuf-all-21.5.tar.gz
tar xf protobuf-all-21.5.tar.gz --no-same-owner
cd protobuf-21.5
./configure --disable-shared
make -j $(nproc)
make install

export CXXFLAGS="-I/usr/local/include"
export LDFLAGS="-L/usr/local/lib"
export LD_LIBRARY_PATH="/usr/local/lib/":$LD_LIBRARY_PATH
ln -s -T $(which g++) /usr/bin/powerpc64le-linux-gnu-g++

cd ~
git clone https://github.com/grpc/grpc-java
cd grpc-java/compiler/
../gradlew build  -PskipAndroid=true
cp build/exe/java_plugin/protoc-gen-grpc-java /usr/local/bin/
export PATH=/usr/local/bin/:$PATH


cd ~
git clone https://github.com/JanusGraph/janusgraph
cd janusgraph
git checkout v${VERSION}
grpc_version=$(grep '<grpc.version>' pom.xml | grep -Po '\d*\.\d*\.\d*')
mvn install:install-file -DgroupId=io.grpc -DartifactId=protoc-gen-grpc-java -Dversion=$grpc_version -Dclassifier=linux-ppcle_64 -Dpackaging=exe -Dfile=$(which protoc-gen-grpc-java)
mvn clean install --projects janusgraph-all -Pjanusgraph-cache -Dmaven.javadoc.skip=true -DskipTests=true --batch-mode --also-make
mvn verify --projects janusgraph-all -Pjanusgraph-cache

