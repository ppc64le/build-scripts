# ----------------------------------------------------------------------------
#
# Package		: grpc-core
# Version		: 1.28.1
# Source repo		: https://github.com/grpc/grpc-java
# Tested on		: UBI8-Minimal
# Script License	: Apache License Version 2.0
# Maintainer		: Pratham Murkute <prathamm@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#			  
# ----------------------------------------------------------------------------

#!/bin/bash

# variables
PKG_NAME="grpc-core"
PKG_VERSION="v1.28.1"

# env variables
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)')
echo "JAVA_HOME is $JAVA_HOME"
export PATH=$PATH:$JAVA_HOME/bin

# clone, build and test latest version
git clone https://github.com/grpc/grpc-java.git 
cd grpc-java
git checkout -b $PKG_VERSION tags/$PKG_VERSION
echo "skipCodegen=true" >> ./gradle.properties
echo "skipAndroid=true" >> ./gradle.properties
cd core/
gradle build | tee $PKG_NAME-$PKG_VERSION.log
tar -zcvf grpc-core.tar.gz ./build
cp ./$PKG_NAME-$PKG_VERSION.log /workspace
cp ./grpc-core.tar.gz /workspace
cd /workspace
rm -rf grpc-java
