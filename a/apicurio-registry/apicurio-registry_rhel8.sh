# ----------------------------------------------------------------------------
#
# Package       : apicurio-registry 
# Version       : 1.3.2.Final
# Source repo   : https://github.com/apicurio/apicurio-registry
# Tested on     : RHEL8
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Shirodkar <amit.shirodkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

yum update -y
yum install wget patch diffutils -y

#download and install protobuf 3.12.0

wget https://github.com/protocolbuffers/protobuf/releases/download/v3.12.0/protobuf-all-3.12.0.tar.gz
tar -xvf protobuf-all-3.12.0.tar.gz
cd protobuf-3.12.0
./autogen.sh
./configure
make
make install
cd ..

git clone https://github.com/grpc/grpc-java.git
cd grpc-java
./buildscripts/make_dependencies.sh
export LDFLAGS=-L/tmp/protobuf/lib
export CXXFLAGS=-I/tmp/protobuf/include
export LD_LIBRARY_PATH=/tmp/protobuf/lib
patch -p1 <<EOF
diff --git a/compiler/build.gradle b/compiler/build.gradle
index 60d3a43..55acee0 100644
--- a/compiler/build.gradle
+++ b/compiler/build.gradle
@@ -105,7 +105,6 @@ model {
                     // Link other (system) libraries dynamically.
                     // Clang under OSX doesn't support these options.
                     linker.args "-Wl,-Bstatic", "-lprotoc", "-lprotobuf", "-static-libgcc",
-                            "-static-libstdc++",
                             "-Wl,-Bdynamic", "-lpthread", "-s"
                 }
                 addEnvArgs("LDFLAGS", linker.args)
EOF
./gradlew -PskipAndroid=true :grpc-compiler:build
cd ..

git clone https://github.com/Apicurio/apicurio-registry.git
cd apicurio-registry/
./mvnw install:install-file -DgroupId=io.grpc -DartifactId=protoc-gen-grpc-java -Dversion=1.32.2 -Dclassifier=linux-ppcle_64 -Dpackaging=exe -Dfile=../grpc-java/compiler/build/libs/protoc-gen-grpc-java-1.34.1.jar
./mvnw clean install

